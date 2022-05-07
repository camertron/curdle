## 1.2.2
* More fixes for the aforementioned bug in `gem build`.
  - We need to use `Dir.chdir` instead of relying on `-C` at all.

## 1.2.1
* Fix bug caused by older versions of `gem build` ignoring the `-C` flag.

## 1.2.0
* Add support for block-based `type_member` calls.

## 1.1.0
* Add support for removing `T::Sig::WithoutRuntime.sig` calls.

## 1.0.0
* Birthday!
