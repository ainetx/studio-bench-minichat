# B9-minichat benchmark tests

This branch is the `oracle` branch with the e2e suite that the B9-minichat benchmark grades.

- `testing/e2e/suites/mini_chat/` is the graded suite, byte for byte. It differs from the suite on `main`.
- The harness in `testing/e2e/` (`conftest.py`, `helpers/`, `lib/`, `pytest.ini`, `testdata/`) is the harness that the benchmark uses.
- `expected_tests.txt` lists the 556 tests that the benchmark grades.
- `excluded_tests.txt` lists the 32 tests that the benchmark deselects. The file gives the reason in its header.
- `constraints.txt` holds the Python package versions of the benchmark image, frozen on Python 3.11.

## Run

```bash
python3.11 -m venv .venv && . .venv/bin/activate
pip install -r testing/e2e/requirements.txt -c testing/e2e/benchmark/constraints.txt
./testing/e2e/benchmark/run.sh
```

`run.sh` builds `cf-gears-example-server` with the features of `suites/mini_chat/e2e.yaml`.
Then it runs the suite in offline mode without the excluded tests.
The JUnit report goes to `testing/e2e/logs/benchmark-junit.xml`.
The suite starts the server and the mock LLM provider itself.

## Grading

The run collects 615 tests. The benchmark grades only the 556 tests of `expected_tests.txt`, and the other 59 do not count.
A graded test passes only with the `passed` result. A skipped graded test counts as failed.

The source is spec-bench `datasets/spec-bench/B9-minichat` at commit `faafc085`.
