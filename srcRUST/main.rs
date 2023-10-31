// [ COPYRIGHT CLAUSE HERE ]
use libautomataci::sample::entity;
use libautomataci::sample::greeter;
use libautomataci::sample::location;

fn main() {
    println!("{}", greeter::process(entity::NAME, location::NAME));
}
