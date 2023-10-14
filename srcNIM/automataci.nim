# [ COPYRIGHT CLAUSE HERE ]
import automatacipkg/Sample/Greeter
import automatacipkg/Sample/Entity
import automatacipkg/Sample/Location




# main
proc main =
    echo "Hello " & Greeter.Process(Entity.Name, Location.Name)
main()
