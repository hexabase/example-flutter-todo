import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hexabase/hexabase.dart';
import 'package:intl/intl.dart';

const projectId = "6350ec6d5a0adcf0808f9d45";
const datastoreId = "6350eccec8074ecb68c5c362";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Hexabase();
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// メイン画面のステートフルウィジェット
class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

// ログイン用ウィジェット
class _MainPageState extends State<MainPage> {
  bool isLogin = false;
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final client = Hexabase.instance;
    final bol = await client.isLogin();
    setState(() {
      isLogin = bol;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 画面表示用のラベル
    return isLogin
        ? TaskListPage()
        : LoginPage(onLogin: () {
            // 認証完了したら受け取るコールバック
            setState(() {
              isLogin = true;
            });
          });
  }
}

// ログイン画面のステートフルウィジェット
class LoginPage extends StatefulWidget {
  final Function? onLogin;
  const LoginPage({Key? key, this.onLogin}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

// ログイン画面用ウィジェット
class LoginPageState extends State<LoginPage> {
  // サンプルの認証情報
  String _email = "atsushi+demo@moongift.co.jp";
  String _password = ".@fuEozC8t6k.Ec__Ah";

  @override
  Widget build(BuildContext context) {
    // 画面表示用のラベル
    return Scaffold(
        // 画面上部に表示するAppBar
        appBar: AppBar(
          title: const Text("Login"),
        ),
        body: Container(
          // 余白を付ける
          padding: const EdgeInsets.all(64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // メールアドレス
              TextFormField(
                initialValue: _email,
                onChanged: (String value) {
                  _email = value;
                },
              ),
              const SizedBox(height: 8),
              // パスワード
              TextFormField(
                obscureText: true,
                initialValue: _password,
                onChanged: (String value) {
                  _password = value;
                },
              ),
              // ログイン実行用のボタン
              TextButton(onPressed: _login, child: const Text("Login"))
            ],
          ),
        ));
  }

  // ログイン処理
  void _login() async {
    // Hexabaseクライアントの呼び出し
    final client = Hexabase.instance;
    // 認証実行
    final bol = await client.login(_email, _password);
    // レスポンスが true なら認証完了
    if (bol) widget.onLogin!();
  }
}

// タスク一覧のステートフルウィジェット
class TaskListPage extends StatefulWidget {
  final Function? onLogin;
  const TaskListPage({Key? key, this.onLogin}) : super(key: key);

  @override
  TaskListPageState createState() => TaskListPageState();
}

// タスク一覧画面用ウィジェット
class TaskListPageState extends State<TaskListPage> {
  List<HexabaseItem> _tasks = [];
  late HexabaseDatastore? _datastore;

  @override
  void initState() {
    super.initState();
    _getTasks();
  }

  // 登録されているタスクを取得する
  void _getTasks() async {
    final client = Hexabase.instance;
    // データストアの設定
    _datastore = client.project(id: projectId).datastore(id: datastoreId);
    // データの取得
    final items = await _datastore!.items();
    setState(() {
      _tasks = items;
    });
  }

  void _add() async {
    // 新しいTodoを取得
    final HexabaseItem? item = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        // 新しいデータの作成
        var item = _datastore!.item();
        // タスクの追加、編集を行う画面への遷移
        return TodoPage(item: item);
      }),
    );
    // レスポンスがあれば、リストに追加
    // キャンセルされた場合は null が来る
    if (item != null) {
      setState(() {
        _tasks.add(item);
      });
    }
  }

  void _edit(int index, HexabaseItem item) async {
    // タップした際には編集画面に遷移する
    await item.getDetail();
    final HexabaseItem? task = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return TodoPage(
          item: item,
        );
      }),
    );
    // 編集後のデータがあれば、リストを更新する
    // キャンセルの場合は null が来る
    if (task != null) {
      setState(() {
        // データ入れ替え
        _tasks[index] = task;
      });
    }
  }

  // タスクの削除処理
  void _delete(int index, DismissDirection direction) async {
    // スワイプされた要素をデータから削除する
    setState(() {
      // データストアから削除
      _tasks[index].delete();
      // 配列からも削除
      _tasks.removeAt(index);
    });
    // Snackbarを表示する
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Task deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // 画面上部に表示するAppBar
        appBar: AppBar(
          title: const Text("Tasks"),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _add,
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final item = _tasks[index];
            // スワイプで削除する機能
            return Dismissible(
                key: Key(item.id!),
                direction: DismissDirection.endToStart,
                // スワイプした際に表示する削除ラベル
                background: Container(
                    padding: EdgeInsets.only(right: 20.0),
                    color: Colors.red.shade500,
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Text('削除',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white)),
                    )),
                // スワイプした際に処理
                onDismissed: (direction) {
                  _delete(index, direction);
                },
                child: Card(
                  child: ListTile(
                    onTap: () {
                      _edit(index, item);
                    },
                    title: Text(item.getAsString('name', defaultValue: "")),
                  ),
                ));
          },
        ));
  }
}

// Todoを受け取るステートフルウィジェット
class TodoPage extends StatefulWidget {
  const TodoPage({
    Key? key,
    required this.item,
  }) : super(key: key);

  final HexabaseItem item;

  @override
  TodoPageState createState() => TodoPageState();
}

// Todoの追加、または更新を行うウィジェット
class TodoPageState extends State<TodoPage> {
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    // 日付に初期値を適用する
    setState(() {
      _date = widget.item
          .getAsDateTime("deadlineDate", defaultValue: DateTime.now());
    });
  }

  // 日付ピッカーで選択した時の処理
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _date ?? DateTime.now(),
        firstDate: DateTime(2022),
        lastDate: DateTime.now().add(const Duration(days: 360)));
    // 日付を選択していればデータストアのアイテムと、表示日付を更新
    if (picked != null) {
      setState(() {
        widget.item.set('deadlineDate', picked);
        _date = picked;
      });
    }
  }

  // 日付を表示する処理
  String _showDate() {
    // 日付が入っていない時の判定用日付
    const defaultDate = "1999-12-31";
    final date = widget.item.getAsDateTime("deadlineDate",
        defaultValue: DateTime.parse(defaultDate));
    if (date.toString().substring(0, 10) == defaultDate) {
      // まだ日付が選択されていない場合
      return "Select date";
    } else {
      // 日付が入力されていた場合
      setState(() {
        _date = date;
      });
      DateFormat outputFormat = DateFormat('yyyy-MM-dd');
      return outputFormat.format(date);
    }
  }

  // データストアへの保存・更新処理
  Future<void> _save() async {
    widget.item.isNotifyToSender = true;
    await widget.item.save();
    // 前の画面に戻る
    Navigator.of(context).pop(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    // 画面表示用のラベル
    final label = widget.item.id != null ? 'Update task' : 'Add task';
    final actions = widget.item.actions();
    return Scaffold(
      // 画面上部に表示するAppBar
      appBar: AppBar(
        title: Text(label),
      ),
      body: Container(
        // 余白を付ける
        padding: const EdgeInsets.all(64),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // タスク名
            TextFormField(
              decoration: const InputDecoration(hintText: "Task name"),
              initialValue: widget.item.getAsString('name', defaultValue: ""),
              onChanged: (String value) {
                widget.item.set('name', value);
              },
            ),
            // タスクの詳細
            TextFormField(
              initialValue:
                  widget.item.getAsString('description', defaultValue: ""),
              decoration: const InputDecoration(hintText: "Task description"),
              maxLines: 5,
              onChanged: (String value) {
                widget.item.set('description', value);
              },
            ),
            // タスクの締め切り
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(_showDate()),
                TextButton(
                    onPressed: _selectDate, child: const Text("Select date")),
              ],
            ),
            // 保存・更新ボタン
            TextButton(
                onPressed: _save,
                child:
                    Text(widget.item.id != null ? "Update task" : "Save task")),
            Row(
                mainAxisSize: MainAxisSize.max,
                children: [const Text("Change status")]),
            Expanded(
              child: ListView.builder(
                  itemCount: actions.length,
                  itemBuilder: (context, index) {
                    final item = actions[index];
                    return ListTile(
                        onTap: () {
                          widget.item.action(item.id!);
                          _save();
                        },
                        title: TextButton(
                            onPressed: () {
                              widget.item.action(item.id!);
                              _save();
                            },
                            child: Text(item.nameLabel!)));
                  }),
            )
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}
