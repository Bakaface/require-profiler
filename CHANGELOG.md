# Change log

## master

## 0.1.1 (2026-04-29)

- Fix JSON printer leaving trailing call-stack bytes in output. ([@ardecvz][])

We overwrite the buffered call-stack text with a (shorter) Speedscope JSON document but never truncate it, breaking JSON validity.

Truncate the file properly.

## 0.1.0 (2026-04-22)

- Initial

[@palkan]: https://github.com/palkan
[@ardecvz]: https://github.com/ardecvz
