// [ COPYRIGHT CLAUSE HERE ]
pub fn process<'a>(name: &'a str, location: &'a str) -> String {
    if name == "" && location == "" {
        return "".to_string();
    } else if name == "" {
        return format!("stranger from {location}!");
    } else if location == "" {
        return format!("{name}!");
    } else {
        return format!("{name} from {location}!");
    }
}
