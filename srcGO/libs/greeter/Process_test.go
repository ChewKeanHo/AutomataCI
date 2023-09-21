// [ COPYRIGHT CLASE HERE]

package greeter

import (
	"testing"
)

// _testProcessScenarios provides the test scenarios to TestProcessAPI suite.
func _testProcessScenarios() []*Scenario {
	return []*Scenario{
		{
			Description: `
Test Process() is able to work with proper name and location.
`,
			Switches: []string{
				_TEST_COND_NAME_PROPER,
				_TEST_COND_LOCATION_PROPER,
				_TEST_EXPECT_OUTPUT_STRING,
			},
		}, {
			Description: `
Test Process() is able to work with proper name and empty location.
`,
			Switches: []string{
				_TEST_COND_NAME_PROPER,
				_TEST_COND_LOCATION_EMPTY,
				_TEST_EXPECT_OUTPUT_STRING,
			},
		}, {
			Description: `
Test Process() is able to work with empty name and proper location.
`,
			Switches: []string{
				_TEST_COND_NAME_EMPTY,
				_TEST_COND_LOCATION_PROPER,
				_TEST_EXPECT_OUTPUT_STRING,
			},
		}, {
			Description: `
Test Process() is able to work with empty name and empty location.
`,
			Switches: []string{
				_TEST_COND_NAME_EMPTY,
				_TEST_COND_LOCATION_EMPTY,
				_TEST_EXPECT_EMPTY_STRING,
			},
		},
	}
}

// TestProcessAPI fully test the Process(...) public function.
func TestProcessAPI(t *testing.T) {
	for i, s := range _testProcessScenarios() {
		s.ID = uint64(i)
		s.Name = "Test Process(...) API"

		// prepare
		name := ""
		location := ""
		expectOutput := false
		expectPanic := false
		output := ""

		for _, condition := range s.Switches {
			if condition == _TEST_COND_NAME_PROPER {
				name = "Alpha"
			}

			if condition == _TEST_COND_LOCATION_PROPER {
				name = "Rivendell"
			}

			if condition == _TEST_EXPECT_OUTPUT_STRING {
				expectOutput = true
			}

			if condition == _TEST_EXPECT_PANIC {
				expectPanic = true
			}
		}

		// test
		panick := _Exec_Test(func() any {
			output = Process(name, location)
			return nil
		})

		// log output
		t.Logf("TEST CASE\n")
		t.Logf("=========\n")

		t.Logf("Test Scenario ID\n")
		t.Logf("	%d\n", s.ID)

		t.Logf("Test Scenario Name\n")
		t.Logf("	%#v\n", s.Name)

		t.Logf("Test Scenario Switches\n")
		for _, condition := range s.Switches {
			t.Logf("	%#v\n", condition)
		}

		t.Logf("Input Name\n")
		t.Logf("	%#v\n", name)

		t.Logf("Input Location\n")
		t.Logf("	%#v\n", location)

		t.Logf("Got Output\n")
		t.Logf("	%#v\n", output)

		t.Logf("Panic State\n")
		t.Logf("	%#v\n", panick)

		t.Logf("\n")

		// assert
		t.Logf("Asserting conditions...\n")
		switch {
		case expectPanic && panick == nil:
			t.Logf("[ FAILED ] Expecting panic but did not happen.\n")
			t.Fail()
		case !expectPanic && panick != nil:
			t.Logf("[ FAILED ] Not expecting panic but did happen.\n")
			t.Fail()
		case expectOutput && output == "":
			t.Logf("[ FAILED ] Expecting output but got empty.\n")
			t.Fail()
		case !expectOutput && output != "":
			t.Logf("[ FAILED ] Not expecting output but got something.\n")
			t.Fail()
		default:
			t.Logf("[ SUCCESS ]\n\n\n")
		}
	}
}
