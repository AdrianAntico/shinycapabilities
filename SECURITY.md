# Security policy

## Reporting

Report suspected vulnerabilities privately to the maintainer through GitHub's
private vulnerability reporting feature when available, or contact Adrian
Antico at `adrianantico@gmail.com`. Do not open a public issue containing exploit
details, credentials, or sensitive data.

Include affected version, reproduction conditions, impact, and a minimal
proof-of-concept without real secrets or private datasets.

## Boundary

R/Shiny owns execution and validation. The browser receives bounded graph and
presentation metadata, not full datasets, fitted models, credentials, arbitrary
R objects, or executable payloads. Proposed nodes are non-executable until host
acceptance. Background results are registered only after success. Saved
workflows exclude live process handles and secrets.

These boundaries reduce exposure but do not constitute production security
certification. Hosts remain responsible for authentication, authorization,
network policy, data governance, sandboxing, and deployment hardening.
