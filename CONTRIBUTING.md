## Contributing

Thank you for the interest in the project!

If you found a bug, have a feature request or need help (ask questions) [open a new issue](https://github.com/fdocr/udl-server/issues/new).

If you implemented a bugfix, a new feature, or updated the docs/tests feel free to __Submit a Pull Request__ so it can be reviewed and hopefully merged.

## Submit a Pull Request

1. Fork the repository
1. Install the dependencies & run locally
   - `shards install`
   - `crystal run src/server.cr`
1. Create your feature branch
   - `git checkout -b my-new-feature`
1. Work on your fix/feature
   - Add tests to avoid regressions in the future
1. Run the tests
   - `KEMAL_ENV=test crystal spec`
   - `SAFELIST="fdo.cr github.com" KEMAL_ENV=test crystal spec`
1. Commit your changes
   - `git commit -am 'Added some feature'`
1. Push to the branch
   - `git push origin my-new-feature`
1. Create new Pull Request
