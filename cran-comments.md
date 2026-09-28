## Submission

This is the first submission of retestR.

## Test environments

* Local: Windows 11, R 4.6.0
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel, release, oldrel-1)
* win-builder: R-devel

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Notes for the reviewer

* The risk index is calibrated by simulation; examples use small simulated data sets and few bootstrap replicates so they run quickly.
* Longer known-truth validation scripts are in `inst/validation/` and are not run during checks.
