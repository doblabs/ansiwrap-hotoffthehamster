@@@@@@@@@@@@@@@@@@@@@@@@@
ansiwrap-hotoffthehamster
@@@@@@@@@@@@@@@@@@@@@@@@@

.. CXREF:
   https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/adding-a-workflow-status-badge

.. image:: https://github.com/doblabs/ansiwrap-hotoffthehamster/actions/workflows/checks-unspecial.yml/badge.svg?branch=release
  :target: https://github.com/doblabs/ansiwrap-hotoffthehamster/actions/workflows/checks-unspecial.yml/badge.svg?branch=release
  :alt: Build Status

.. CXREF: https://app.codecov.io/github.com/doblabs/ansiwrap-hotoffthehamster/settings/badge

.. image:: https://codecov.io/gh/doblabs/ansiwrap-hotoffthehamster/branch/release/graph/badge.svg?token=XXX
  :target: https://app.codecov.io/gh/doblabs/ansiwrap-hotoffthehamster
  :alt: Coverage Status

.. image:: https://readthedocs.org/projects/ansiwrap-hotoffthehamster/badge/?version=latest
  :target: https://ansiwrap-hotoffthehamster.readthedocs.io/en/latest/
  :alt: Documentation Status

.. image:: https://img.shields.io/github/v/release/doblabs/ansiwrap-hotoffthehamster.svg?style=flat
  :target: https://github.com/doblabs/ansiwrap-hotoffthehamster/releases
  :alt: GitHub Release Status

.. image:: https://img.shields.io/pypi/v/ansiwrap-hotoffthehamster.svg
  :target: https://pypi.org/project/ansiwrap-hotoffthehamster/
  :alt: PyPI Release Status

.. image:: https://img.shields.io/pypi/pyversions/ansiwrap-hotoffthehamster.svg
  :target: https://pypi.org/project/ansiwrap-hotoffthehamster/
  :alt: PyPI Supported Python Versions

.. image:: https://img.shields.io/github/license/doblabs/ansiwrap-hotoffthehamster.svg?style=flat
  :target: https://github.com/doblabs/ansiwrap-hotoffthehamster/blob/release/LICENSE
  :alt: License Status

|

.. ISOFF/2023-12-16: Upstream (forked-from) badges:
..
.. | |travisci| |version| |versions| |impls| |wheel| |coverage|
..
.. .. |travisci| image:: https://api.travis-ci.org/jonathaneunice/ansiwrap.svg
..     :target: http://travis-ci.org/jonathaneunice/ansiwrap
..
.. .. |version| image:: http://img.shields.io/pypi/v/ansiwrap.svg?style=flat
..     :alt: PyPI Package latest release
..     :target: https://pypi.python.org/pypi/ansiwrap
..
.. .. |versions| image:: https://img.shields.io/pypi/pyversions/ansiwrap.svg
..     :alt: Supported versions
..     :target: https://pypi.python.org/pypi/ansiwrap
..
.. .. |impls| image:: https://img.shields.io/pypi/implementation/ansiwrap.svg
..     :alt: Supported implementations
..     :target: https://pypi.python.org/pypi/ansiwrap
..
.. .. |wheel| image:: https://img.shields.io/pypi/wheel/ansiwrap.svg
..     :alt: Wheel packaging support
..     :target: https://pypi.python.org/pypi/ansiwrap
..
.. .. |coverage| image:: https://img.shields.io/badge/test_coverage-99%25-0000FF.svg
..     :alt: Test line coverage
..     :target: https://pypi.python.org/pypi/ansiwrap

``ansiwrap`` wraps text, like the standard ``textwrap`` module.
But it also correctly wraps text that contains ANSI control
sequences that colorize or style text.

Where ``textwrap`` is fooled by the raw string length of those control codes,
``ansiwrap`` is not; it understands that however much those codes affect color
and display style, they have no logical length.

The API mirrors the ``wrap``, ``fill``, and ``shorten``
functions of ``textwrap``. For example::

    from __future__ import print_function
    from colors import *     # ansicolors on PyPI
    from ansiwrap import *

    s = ' '.join([red('this string'),
                  blue('is going on a bit long'),
                  green('and may need to be'),
                  color('shortened a bit', fg='purple')])

    print('-- original string --')
    print(s)
    print('-- now filled --')
    print(fill(s, 20))
    print('-- now shortened / truncated --')
    print(shorten(s, 20, placeholder='...'))

It also exports several other functions:

* ``ansilen`` (giving the effective length of a string, ignoring ANSI control codes)
* ``ansi_terminate_lines`` (propagates control codes though a list of strings/lines
  and terminates each line.)
* ``strip_color`` (removes ANSI control codes from a string)

See also the enclosed ``demo.py``.

.. image:: https://github.com/doblabs/ansiwrap-hotoffthehamster/blob/release/docs/assets/00000569.png
   :align: center
