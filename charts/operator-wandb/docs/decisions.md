# Design Decisions

This documentation collects reasoning and decisions made regarding the design of
the Helm charts in this repository. Proposals welcome, see Decision Making for
how we apply decisions.

- [Design Decisions](#design-decisions)
  - [Attempt to catch problematic configurations](#attempt-to-catch-problematic-configurations)
  - [Sub-charts are deployed from global chart](#sub-charts-are-deployed-from-global-chart)

## Attempt to catch problematic configurations

Due to the complexity of these charts and their level of flexibility, there are
some overlaps where it is possible to produce a configuration that would lead to
an unpredictable, or entirely non-functional deployment. In an effort to prevent
known problematic settings combinations, we have implemented template logic
designed to detect and warn the user that their configuration will not work.
This replicates the behavior of deprecations, but is specific to ensuring
functional configuration.

This logic should be defined in `_checkConfig_*.tpl` files.

## Sub-charts are deployed from global chart

All sub-charts of this repository are designed to be deployed via the global
chart. We have not tested deployment of each individually charts. You can
disable services via the configuration.

This decision simplifies both the use and maintenance of the repository as a
whole.
