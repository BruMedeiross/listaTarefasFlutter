import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; //plug in leitura e salvamento em json

void main(){
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //controler
  final _toDoController = TextEditingController();

  List _toDoList = [];


  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  //LER DADOS GRAVADOS NO APP
  @override
  void initState() {
    super.initState();//CONTROL+O

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  //funcao para add itens na lista
  void _addToDo() {
    setState(() {   //atualiza o stado

      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;   //pega o texto do textfield
      _toDoController.text = ""; //reseta
      newToDo["ok"] = false;
      _toDoList.add(newToDo); //pega os dado e insere na lista

      _saveData();
    });
  }
    //refresh - ordena a lista
  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(//expandira o max que puder
                  //texto
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  )
                ),
                //botao
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,  //chama funcao addToDo
                )
              ],
            ),
          ),
          Expanded(//tamanho da lista
            child: RefreshIndicator(onRefresh: _refresh, //atualzacao
              child: ListView.builder( //tipo uma rv
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length, //quantidade de itens listas
                  itemBuilder: buildItem),),
          )
        ],
      ),
    );
  }

  //construtor do formato dos itens listas
  Widget buildItem(BuildContext context, int index){
    return Dismissible( //resposavel pela parte de ARRASTAR
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(// epecificação
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),
      ),
      direction: DismissDirection.startToEnd,

      child: CheckboxListTile(  //lista -checkbox de acordo com a insercao de dados
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(  //icone de acordo com a condicao se estiver ok ou nao
          child: Icon(_toDoList[index]["ok"] ?
          Icons.check : Icons.error),),
        onChanged: (c){ //se for marcado o check
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction){//funcao qdo arrastar remover ou desfazer
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(//mensagem removida e opçao desfazer
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(label: "Desfazer",
                onPressed: () {
                  setState(() {//sempre ao atualizar algo - set state
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 3),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);

        });
      },
    );
  }

  // local onde sera salvo
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory(); //diretorio onde sera salvo
    return File("${directory.path}/data.json"); //caminho
  }

  //salvando os dados no local
  Future<File> _saveData() async {
    String data = json.encode(_toDoList); //convertendo lista em json

    final file = await _getFile();
    return file.writeAsString(data);
  }

  //lendo os dados
  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

}

