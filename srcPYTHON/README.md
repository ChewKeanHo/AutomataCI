# Developer README First
This is a workspace generated from
[Holloway's Template](https://github.com/ChewKeanHo/Template) repository
specifically for Python Project. Unlike the general README.md file in the root
repository, this is specific for Python deployment.




## PIP Installation and Updates
They're executed in the Native CI's `prepare` job.




## Test Execution
The native CI is configured to run all unit test codes
**next to their respective subject source codes** and uses `_test.py` suffix.
It is not configured to use the unified `tests` directory.

This uses `coverage` (external package) and `unittest` modules to generate
meaningful and insightful test reports. The default location is stored inside:

```
# UNIX (e.g. Linux & MacOS)
${PROJECT_PATH_ROOT}/${PROJECT_PATH_TEMP}/python-test-report

# WINDOWS
$PROJECT_PATH_ROOT\$PROJECT_PATH_TEMP\python-test-report
```

You can open the `index.html` file to view the actual coverage mapping which
can help you to perform pinpoint testing with optimal amount of test cases.
