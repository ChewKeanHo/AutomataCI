# [ COPYRIGHT CLAUSE HERE ]
import Greeter


# define test libraries
type
    Scenario = object
        ID: uint64
        Name: string
        Description: string




# define test algorithm
proc test_process_api(s: var Scenario, name: string, location: string): int =
    var str: string = ""

    # test
    str = Greeter.Process(name, location)

    # log output
    echo "TEST CASE"
    echo "========="
    echo "Test Scenario ID"
    echo "  ", s.ID
    echo "Test Scenario Name"
    echo "  ", s.Name
    echo "Test Scenario Description"
    echo "  ", s.Description
    echo "Input Name"
    echo "  ", name
    echo "Input Location"
    echo "  ", location
    echo "Got Output:"
    echo "  ", str
    echo ""

    # assert
    echo "Asserting conditions..."
    if str != "":
        if name == "" and location == "":
            echo "[ FAILED ] Expecting string but got empty instead.\n\n\n"
            return 1
    else:
        if name != "" or location != "":
            echo "[ FAILED ] Expecting empty string but got result instead.\n\n\n"
            return 1

    # report status
    echo "[ PASSED ]\n\n\n"
    return 0




# execute main test
proc main =
    var s = Scenario(ID: 0, Name: "Test Process(...) API")

    s.Description = "Test Process() is able to work with proper name and location."
    if test_process_api(s, "Alpha", "Rivendell") != 0:
        return
    s.ID += 1

    s.Description = "Test Process() is able to work with proper name and empty location."
    if test_process_api(s, "Alpha", "") != 0:
        return
    s.ID += 1

    s.Description = "Test Process() is able to work with empty name and proper location."
    if test_process_api(s, "Alpha", "") != 0:
        return
    s.ID += 1

    s.Description = "Test Process() is able to work with empty name and empty location."
    if test_process_api(s, "Alpha", "") != 0:
        return
    s.ID += 1

main()
