Fight Flash Fraud, Ported to Aether
===================================

This repository is an Aether port of F3, Fight Flash Fraud. It tests
flash media by writing deterministic ``.h2w`` files and reading them back
to verify that the device really stores the capacity it claims.

The active ``main`` branch is Aether-only. The upstream C implementation
is preserved on the ``original_c_code`` branch for reference and history.


What is here
============

- ``src/f3.ae``: single CLI entrypoint with ``write`` and ``read`` subcommands.
- ``src/f3core/module.ae``: shared F3 write/read verification logic.
- ``app/fight_flash_fraud.ae``: Aether UI app using ``aether-ui``.
- ``tests/``: Aeocha unit tests and an AetherUIDriver UI test.
- ``bootstrap.sh``: convenience bootstrap for sibling Aether dependencies.


Build
=====

The normal build expects ``ae`` and ``aetherc`` on ``PATH``. For local
development with sibling checkouts, run:

::

    ./bootstrap.sh

That checks for:

- ``~/scm/aether``
- ``~/scm/aether-ui``
- ``~/scm/aeocha``

Then it builds the app and runs the tests.

To build manually:

::

    make
    make app

The outputs are:

- ``build/f3``
- ``build/fight_flash_fraud``


CLI
===

Write a test pattern to a mounted flash filesystem:

::

    build/f3 write --start-at=1 --end-at=32 --size-mb=1024 /media/$USER/FLASH

Read and verify the files:

::

    build/f3 read --start-at=1 --end-at=32 /media/$USER/FLASH

For a small simulation:

::

    mkdir -p /tmp/f3-aether-ui
    build/f3 write --start-at=1 --end-at=1 --size-mb=1 /tmp/f3-aether-ui
    build/f3 read --start-at=1 --end-at=1 /tmp/f3-aether-ui


UI App
======

Build and launch:

::

    make app
    ./build/fight_flash_fraud

The UI offers:

- path selection for flash-like mounted block devices
- write progress as a proportional grid
- read/verify results as check/cross grid cells
- a human result such as ``Flash size is correct for tested 1MB. No fraud detected.``
- hidden detailed log via ``Show log``


Tests
=====

Run all tests:

::

    make test

The test suite includes:

- Aeocha unit coverage for app-facing text/verdict helpers.
- AetherUIDriver coverage for the UI: initial disabled read button, write,
  read enablement, grid update, and no-fraud verdict.

On Linux, ``scripts/test-ui.sh`` tries the real display first. If the
AetherUIDriver endpoint does not come up, it falls back to ``xvfb-run`` when
available. To force the real display path:

::

    F3_UI_NO_XVFB=1 make test-ui


Branch Layout
=============

``main``
    Aether port. This is the active branch for development and publishing.

``original_c_code``
    Untouched upstream F3 C snapshot. Use this as the historical link to the
    original implementation; do not mix Aether port commits into it.


License
=======

This port keeps the upstream F3 license. See ``LICENSE``.
