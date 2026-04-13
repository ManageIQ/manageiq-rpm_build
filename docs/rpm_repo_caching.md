# RPM Repository Caching Implementation

## Overview

The RPM repository update process has been optimized to use createrepo's caching mechanism, significantly reducing bandwidth usage and processing time by avoiding the need to download all RPMs on every update.

## How It Works

### Previous Implementation (Inefficient)
1. Download ALL RPMs from S3 to local directory (potentially gigabytes)
2. Generate repository metadata from scratch
3. Upload new RPMs and metadata to S3

### New Implementation (Efficient)
1. Download createrepo cache from S3 (contains RPM hashes, much smaller)
2. Check which RPMs are new by comparing against existing S3 repository
3. Download ONLY new RPMs
4. Use `createrepo --update --cachedir` to incrementally update metadata
5. Upload only new RPMs, updated metadata, and updated cache

## Key Benefits

- **Reduced Bandwidth**: Only downloads new RPMs instead of entire repository
- **Faster Updates**: Incremental metadata updates vs full regeneration
- **Lower Storage**: Cache files (RPM hashes) are much smaller than actual RPMs
- **Cost Savings**: Less data transfer and processing time

## Initial Setup

Before using the new implementation, you must run the one-time initialization script to generate the initial createrepo cache:

```bash
./bin/initialize_rpm_cache.rb
```

This script will:
1. Download all existing RPMs
2. Generate createrepo metadata with cache
3. Upload the cache to S3 under `createrepo_cache/` prefix

**Note**: This is a one-time operation. After the initial cache is created, subsequent updates will be incremental.

## Regular Usage

After initialization, use the regular update command as before:

```bash
./bin/update_rpm_repo.rb
```

The script will now:
1. Download the createrepo cache from S3
2. Identify and download only new RPMs
3. Update metadata incrementally
4. Upload changes back to S3

## Technical Details

### Cache Storage
- Cache is stored in S3 under the `createrepo_cache/` prefix
- Each repository directory has its own cache subdirectory
- Cache contains RPM headers and checksums, not full RPM files

### createrepo Options Used
- `--update`: Incrementally update existing repository metadata
- `--cachedir`: Specify directory for RPM header cache

### File Structure
```
S3 Bucket:
├── builds/                    # Source RPMs
├── release/                   # Published repository
│   ├── 21-uhlmann/
│   │   └── el9/
│   │       ├── noarch/
│   │       ├── src/
│   │       └── x86_64/
│   │           ├── *.rpm
│   │           └── repodata/
└── createrepo_cache/          # RPM metadata cache
    ├── release_21-uhlmann_el9_noarch/
    ├── release_21-uhlmann_el9_src/
    └── release_21-uhlmann_el9_x86_64/
```

## Implementation Files

- [`bin/initialize_rpm_cache.rb`](../bin/initialize_rpm_cache.rb) - One-time initialization script
- [`lib/manageiq/rpm_build/rpm_repo.rb`](../lib/manageiq/rpm_build/rpm_repo.rb) - Updated repository update logic

## Troubleshooting

### Cache Corruption
If the cache becomes corrupted, you can regenerate it by running:
```bash
./bin/initialize_rpm_cache.rb
```

### Missing Cache
If the cache is missing from S3, the update script will log a warning and the next run of `initialize_rpm_cache.rb` will recreate it.

### Performance Comparison

**Before (downloading all RPMs):**
- Download: ~5-10 GB per update
- Time: 15-30 minutes depending on connection
- Metadata generation: Full rebuild

**After (using cache):**
- Download: ~10-50 MB cache + new RPMs only
- Time: 2-5 minutes for typical updates
- Metadata generation: Incremental update

## References

The implementation is based on the createrepo caching technique described in the community:

> We ended up solving this with createrepo with the "update" and "--cachedir" options. This instructs createrepo to store RPM hashes (which can themselves be stored on S3) so that it doesn't have to pull down every RPM each time.
