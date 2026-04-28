# Change log

## master

- Fix JSON printer leaving trailing call-stack bytes in output. ([@ardecvz][])

We overwrite the buffered call-stack text with a (shorter) Speedscope JSON document but never truncate it, breaking JSON validity.

Truncate the file properly.

[@palkan]: https://github.com/palkan
[@ardecvz]: https://github.com/ardecvz
