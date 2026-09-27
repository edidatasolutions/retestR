---
title: 'retestR: Model-based anomaly detection for repeat test-takers'
tags:
  - R
  - psychometrics
  - test security
  - item response theory
  - response times
authors:
  - name: Daniel Edi
    orcid: 0000-0000-0000-0000   # TODO: your ORCID
    affiliation: 1
affiliations:
  - name: TODO affiliation
    index: 1
date: 27 September 2026
bibliography: paper.bib
---

<!-- DRAFT. Verify every reference and number before submission. Check the
journal's policy on disclosing AI-assisted software and writing. -->

# Summary

Licensure programs see many repeat test-takers, and some gains are too large
or too oddly patterned to be credible. Programs commonly flag repeaters on raw
score gain, which also flags candidates who legitimately studied or
remediated. `retestR` instead models the gain each repeater *should* show and
flags departures using evidence that preknowledge leaves behind. It fits an
expected-gain model by marginal maximum likelihood from the first attempt and
only the *new* items of the second attempt, so compromised items cannot
inflate the expectation and regression to the mean is handled by conditioning.
It computes posterior-predictive evidence from exposed-item performance and,
via a lognormal response-time model [@vanderlinden2006], from response speed.
The evidence is combined into a risk index calibrated by parametric bootstrap
under the no-misconduct model, with Benjamini-Hochberg q-values [@bh1995].

# Statement of need

Existing R tools detect aberrance within a single administration. Security
work on item preknowledge [@sinharay2017; @wollack2013] motivates comparing
performance on exposed and secure items, but no package applies this to
retest trajectories with a model of legitimate growth and calibrated
false-positive rates. `retestR` is designed for exam security committees that
must justify each flag.

# Validation

In a known-truth simulation (3,000 repeaters, 40% remediated, 5% with
preknowledge), the default risk index flagged 100% of preknowledge cases at a
1.0% false-positive rate among honest repeaters. Flagging the same number of
candidates by raw gain caught 45% and flagged 86 honest remediated candidates
(vs 13). Under no misconduct, flag rates matched nominal levels (5.4%, 1.2%
and 0.13% at 0.05, 0.01 and 0.001).

# Acknowledgements

TODO.

# References
