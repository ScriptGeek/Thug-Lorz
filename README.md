# Thug-Lorz
Drug Wars clone written in Ruby for the command-line console

This video game was inspired by my curiosity to learn the Ruby programming language.

The implementation relies heavily upon a menu system, which was developed from scratch.  I've never created a command-line console menu system before so I put some thought into creating something robust yet minimalistic.  By capitalizing upon the powerful lambda expression this vital component was easily composed into something that can be used for any command-line interface from very simple menus to extremely complex multilevel nested menu structures.  This system incorporates user input validation and custom event handling for precise management of program flow with minimal involvement of menu related details.  Here's a quick blurb on how to use the Menu class to quickly and easily create a simple non-nested menu in a command-line driven program:


1. Create a main menu

	main_menu = Menu.new(“Main”)


2. Set content

	main_menu.set_content(lambda {puts ”Press A to do this, press B to do that, or Q to Quit”})


3. Assign options

	main_menu.add_option(“A”, true, “Option A”, [{rule: lambda {true}, on_valid: lambda{puts “You pressed A”}}])

	main_menu.add_option(“B”, true, “Option B”, [{rule: lambda {true}, on_valid: lambda{puts “You pressed B”}}])

	main_menu.add_option(“Q”, true, “Quit”, [{rule: lambda {true}, on_valid: lambda{Menu.get_menu(“Main”).exit_menu}}])


4. Display the main menu

	main_menu.display

 To create a nested menu system just define another menu, like the Main Menu is defined, before the option is set and then call its display method inside its on_valid lambda expression.  To use the built in user input prompt and validation system, just call Menu.handle_input_prompt and provide the prompt string that displays and the various options to handle all the cases in which the input should be validated.

For example, this is how an array of options can be defined for the handle_input_prompt options parameter:

options =
    [{conditions: [{
        rule: lambda {Menu.prompt_input.upcase == "Y"}, on_fail: lambda {}}
      ],
      handler: lambda {Menu.get_menu("Main").exit_menu},
      reprompt_on_success: false,
      reprompt_on_failure: false,
      reprompt_while: lambda {false}
      },
     {conditions: [{
        rule: lambda {Menu.prompt_input.upcase == "N"}, on_fail: lambda {}}
      ],
      handler: lambda {},
      reprompt_on_success: false,
      reprompt_on_failure: false,
      reprompt_while: lambda {false}}
    ])

Each option is a hash consisting of an array of conditions for that option, an option handler method, two booleans which specify whether the prompt should repeat in either outcome of the evaluated conditions, and another method that determines if the prompt should repeat with a much more robust specification using a lambda expression for virtually unlimited control.

Example usage of the above options:

main_menu.add_option("q", false, "Quit", [{ rule: lambda {true}, on_invalid: lambda{} }], lambda {
  Menu.handle_input_prompt("Are you sure you want to quit? (y/n) ", options)
})

As shown, the Menu.handle_input_prompt method is called inside the add_option event handler for the 'q' keypress event.

The Thug Lorz game heavily depends upon the structure this menu system provides, which made the development of the game very simple and easy.  Refer to the game's source code for examples in how the menu system can be used for nested menus.
