# [ COPYRIGHT CLASE HERE]
def Process(name: str, location: str) -> str:
    """
    Generate a printable statement for a name and a location.
    """
    if name == "" and location == "":
        return ""
    elif name == "":
        return "stranger from " + location + "!"
    elif location == "":
        return name + "!"
    else:
        return name + " from " + location + "!"
