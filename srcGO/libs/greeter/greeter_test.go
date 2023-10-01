// [ COPYRIGHT CLASE HERE]

// This is a package-wide internal test values' common definitions used by
// multiple test suites. By default it faciliates table-driven testing for
// robust and rich test coverage.

package greeter

type Verdict uint8

type Scenario struct {
	ID          uint64
	Name        string
	Description string
	Switches    []string
	Verdict     Verdict
}

const (
	_TEST_COND_NAME_EMPTY  = "empty name"
	_TEST_COND_NAME_PROPER = "proper name"

	_TEST_COND_LOCATION_EMPTY  = "empty location"
	_TEST_COND_LOCATION_PROPER = "proper location"
)

const (
	_TEST_EXPECT_OUTPUT_STRING = "expect string output"
	_TEST_EXPECT_EMPTY_STRING  = "expect empty output"
	_TEST_EXPECT_PANIC         = "expect panic"
)

const (
	VERDICT_PASS Verdict = 0
	VERDICT_FAIL Verdict = 1
	VERDICT_SKIP Verdict = 2
)

func _Exec_Test(function func() any) (out any) {
	defer func() {
		err := recover()
		if err != nil {
			out = err
		}
	}()

	out = function()
	return out
}
