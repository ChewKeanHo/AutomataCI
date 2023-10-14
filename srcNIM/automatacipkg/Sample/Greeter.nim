# [ COPYRIGHT CLASE HERE ]




proc Process*(name, location: string): string =
    ## Process it to generate a sample response based on a given name and
    ## location.
    if name == "" and location == "":
        return ""
    elif name == "":
        return "stranger from " & location & "!"
    elif location == "":
        return name & "!"
    else:
        return name & " form " & location & "!"
