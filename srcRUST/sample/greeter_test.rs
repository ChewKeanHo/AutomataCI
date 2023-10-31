// [ COPYRIGHT CLAUSE HERE ]
use crate::sample::greeter;

const NAME: &str = "Alpha";
const LOCATION: &str = "Rivendell";

#[test]
fn it_is_able_to_work_with_proper_name_and_proper_location() {
    let output = greeter::process(NAME, LOCATION);
    assert_ne!(output, "");
}

#[test]
fn it_is_able_to_work_with_proper_name_and_empty_location() {
    let output = greeter::process(NAME, "");
    assert_ne!(output, "");
}

#[test]
fn it_is_able_to_work_with_empty_name_and_proper_location() {
    let output = greeter::process("", LOCATION);
    assert_ne!(output, "");
}

#[test]
fn it_is_able_to_work_with_empty_name_and_empty_location() {
    let output = greeter::process("", "");
    assert_eq!(output, "");
}
