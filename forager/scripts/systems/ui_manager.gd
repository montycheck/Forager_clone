extends Node

signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)

var current_menu: String = ""

func open_menu(menu_name: String):
	if current_menu == menu_name:
		close_menu()
		return
	
	close_menu()
	current_menu = menu_name
	menu_opened.emit(menu_name)
	
func close_menu():
	if current_menu == "":
		return
		
	var closing_menu := current_menu
	current_menu = ""
	menu_closed.emit(closing_menu)
	
func has_menu_open():
	return current_menu != ""
