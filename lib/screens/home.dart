import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todolist/constants/colors.dart';
import 'package:todolist/widgets/todo_item.dart';
import 'package:todolist/model/todo.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Box<ToDo> todoBox;
  final _todoController = TextEditingController();
  List<ToDo> _foundToDo = [];
  String? id;
  bool editMode = false;

  @override
  void initState() {
    super.initState();
    todoBox = Hive.box<ToDo>('todos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tdBGColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            child: Column(
              children: [
                searchBox(),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: todoBox.listenable(),
                    builder: (context, Box<ToDo> box, _) {
                      final todoList = box.values.toList();
                      if (todoList.isEmpty) {
                        return const Center(child: Text('No ToDos'));
                      } else {
                        _foundToDo=todoList;
                        return ListView(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                top: 50,
                                bottom: 20,
                              ),
                              child: const Text(
                                "All ToDos",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            for (ToDo todo in _foundToDo.reversed)
                              ToDoItem(
                                todo: todo,
                                onToDoChanged: _handleToDoChange,
                                onDeleteItem: _deleteToDoItem,
                                onChecked: _handleChecked,
                              )
                          ],
                        );
                      }
                    },
                  ),
                )
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 20,
                      right: 20,
                      left: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.grey,
                            offset: Offset(0.0, 0.0),
                            blurRadius: 10.0,
                            spreadRadius: 0.0),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _todoController,
                      decoration: const InputDecoration(
                        hintText: 'Add a new todo',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    bottom: 20,
                    right: 10,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      _addToDoItem(_todoController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tdBlue,
                      minimumSize: const Size(60, 60),
                      elevation: 10,
                    ),
                    child: const Text(
                      '+',
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (editMode)
                  Container(
                    margin: const EdgeInsets.only(
                      bottom: 20,
                      right: 10,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _cancelEditMode();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tdBlue,
                        minimumSize: const Size(60, 60),
                        elevation: 5,
                      ),
                      child: const Text(
                        'X',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _handleChecked(ToDo todo) {
    setState(() {
      todo.isDone = !todo.isDone;
      todoBox.put(todo.id, todo);
    });
  }

  void _handleToDoChange(ToDo todo) {
    setState(() {
      _todoController.text = todo.todoText!;
      id = todo.id;
      editMode = true;
    });
  }

  void _deleteToDoItem(String id) {
    setState(() {
      todoBox.delete(id);
    });
  }

  void _addToDoItem(String todoText) async {
    if (id == null) {
      var newTodo = ToDo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        todoText: todoText,
      );

      todoBox.put(newTodo.id, newTodo);
    } else {
      var existingTodo = todoBox.get(id);
      if (existingTodo != null) {
        existingTodo.todoText = todoText;
        todoBox.put(id, existingTodo);
      }
      id = null;
      editMode = false;
    }
    setState(() {
      _todoController.clear();
    });
  }


  void _runFilter(String enteredKeyword) {
    List<ToDo> results = [];
    if (enteredKeyword.isEmpty) {
      results = todoBox.values.toList();
    } else {
      results = todoBox.values
          .where((element) =>
          element.todoText!.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _foundToDo = results;
    });
  }

  Widget searchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        onChanged: (value) => _runFilter(value),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(0),
          prefixIcon: Icon(
            Icons.search,
            color: tdBlack,
            size: 20,
          ),
          prefixIconConstraints: BoxConstraints(
            maxHeight: 20,
            minWidth: 25,
          ),
          border: InputBorder.none,
          hintText: 'Search',
          hintStyle: TextStyle(color: tdGrey),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: tdBGColor,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(
            Icons.menu,
            color: tdBlack,
            size: 30,
          ),
          SizedBox(
            height: 40,
            width: 40,
            child: ClipRRect(
              // child: ,
              borderRadius: BorderRadius.circular(20),
            ),
          )
        ],
      ),
    );
  }

  void _cancelEditMode() {
    setState(() {
      editMode = false;
      id = null;
      _todoController.clear();
    });
  }
}
