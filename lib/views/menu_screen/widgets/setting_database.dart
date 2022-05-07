import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';

///
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

///
import 'package:moodexample/generated/l10n.dart';
import 'package:moodexample/common/utils.dart';

///
import 'package:moodexample/view_models/mood/mood_view_model.dart';
import 'package:moodexample/services/mood/mood_service.dart';
import 'package:moodexample/models/mood/mood_model.dart';

/// 数据
class SettingDatabase extends StatefulWidget {
  const SettingDatabase({Key? key}) : super(key: key);

  @override
  State<SettingDatabase> createState() => _SettingDatabaseState();
}

class _SettingDatabaseState extends State<SettingDatabase>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              child: Text(
                S.of(context).app_setting_database_export_data,
                style: TextStyle(
                  fontSize: 14.sp,
                ),
              ),
            ),
            Tab(
              child: Text(
                S.of(context).app_setting_database_import_data,
                style: TextStyle(
                  fontSize: 14.sp,
                ),
              ),
            )
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              /// 导出数据
              Container(
                margin: EdgeInsets.only(top: 64.h),
                child: const ExportDatabaseBody(),
              ),

              /// 导入数据
              Container(
                margin: EdgeInsets.only(top: 64.h),
                child: const ImportDatabaseBody(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 导入数据
class ImportDatabaseBody extends StatefulWidget {
  const ImportDatabaseBody({Key? key}) : super(key: key);

  @override
  State<ImportDatabaseBody> createState() => _ImportDatabaseBodyState();
}

class _ImportDatabaseBodyState extends State<ImportDatabaseBody> {
  /// 数据错误位置
  String _errorPath = "";

  /// 数据是否正在导入
  bool _isImport = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            /// 导入按钮
            SizedBox(
              width: 128.h,
              height: 128.h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withAlpha(140),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      offset: const Offset(0, 5.0),
                      blurRadius: 15.0,
                      spreadRadius: 2.0,
                    )
                  ],
                  shape: BoxShape.circle,
                ),
                child: _isImport
                    ? CupertinoActivityIndicator(
                        radius: 14.sp,
                        color: const Color(0xFFFFFFFF),
                      )
                    : Material(
                        color: Colors.transparent,
                        child: IconButton(
                          splashColor: Colors.white10,
                          highlightColor: Colors.white10,
                          icon: const Icon(Remix.arrow_up_line),
                          iconSize: 48.sp,
                          color: const Color(0xFFFFFFFF),
                          padding: EdgeInsets.all(22.w),
                          onPressed: () async {
                            vibrate();
                            setState(() {
                              _isImport = true;
                              _errorPath = "";
                            });
                            try {
                              Map results = await importDatabase(context);
                              setState(() {
                                _isImport = false;
                                vibrate();
                              });
                              switch (results["state"]) {
                                case 0:
                                  _errorPath = results["errorPath"];
                                  Fluttertoast.showToast(
                                    msg: S
                                        .of(context)
                                        .app_setting_database_import_data_toast_error,
                                    toastLength: Toast.LENGTH_LONG,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 1,
                                    backgroundColor: Colors.black54,
                                    textColor: Colors.white,
                                    fontSize: 12.sp,
                                  );
                                  break;
                                case 1:
                                  Fluttertoast.showToast(
                                    msg: S
                                        .of(context)
                                        .app_setting_database_import_data_toast_success,
                                    toastLength: Toast.LENGTH_LONG,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 1,
                                    backgroundColor: Colors.black54,
                                    textColor: Colors.white,
                                    fontSize: 12.sp,
                                  );

                                  /// 更新心情数据
                                  MoodViewModel _moodViewModel =
                                      Provider.of<MoodViewModel>(context,
                                          listen: false);

                                  /// 获取所有有记录心情的日期
                                  MoodService.getMoodRecordedDate(
                                      _moodViewModel);

                                  /// 处理日期
                                  String moodDatetime = _moodViewModel
                                      .nowDateTime
                                      .toString()
                                      .substring(0, 10);

                                  /// 获取心情数据
                                  MoodService.getMoodData(
                                      _moodViewModel, moodDatetime);
                                  break;
                                default:
                                  break;
                              }
                            } catch (e) {
                              print(e);
                            }
                          },
                        ),
                      ),
              ),
            ),
            Column(
              children: [
                /// 错误文件下载
                Builder(builder: (context) {
                  return _errorPath.isNotEmpty
                      ? Container(
                          width: 64.h,
                          height: 64.h,
                          padding: EdgeInsets.only(left: 12.w),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  const Color(0xFFf5222d),
                                  const Color(0xFFf5222d).withAlpha(140),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFf5222d).withOpacity(0.2),
                                  offset: const Offset(0, 5.0),
                                  blurRadius: 15.0,
                                  spreadRadius: 2.0,
                                )
                              ],
                              shape: BoxShape.circle,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: TextButton(
                                child: Text(
                                  S
                                      .of(context)
                                      .app_setting_database_import_data_button_error,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all(
                                      const CircleBorder()),
                                ),
                                onPressed: () async {
                                  vibrate();

                                  /// 分享文件
                                  Share.shareFiles([_errorPath]);
                                },
                              ),
                            ),
                          ),
                        )
                      : const SizedBox();
                }),

                /// 下载模板
                Container(
                  width: 64.h,
                  height: 64.h,
                  padding: EdgeInsets.only(left: 12.w, top: 12.w),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withAlpha(140),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          offset: const Offset(0, 5.0),
                          blurRadius: 15.0,
                          spreadRadius: 2.0,
                        )
                      ],
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: TextButton(
                        child: Text(
                          S
                              .of(context)
                              .app_setting_database_import_data_button_template,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all(const CircleBorder()),
                        ),
                        onPressed: () async {
                          vibrate();
                          String filePath = await importDatabaseTemplate();

                          /// 分享文件
                          Share.shareFiles([filePath]);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// 导入模板
Future<String> importDatabaseTemplate() async {
  /// 获取APP文件临时根路径
  final directory = (await getTemporaryDirectory()).path;

  /// 保存文件路径及名称
  final String filePath = "$directory/system/database/importTemplate";
  final String fileName = "$filePath/MoodExample导入模板.xlsx";

  /// 删除之前的缓存
  try {
    Directory(filePath).deleteSync(recursive: true);
  } catch (e) {
    print(e);
  }

  /// 创建Excel
  Excel excel = Excel.createExcel();

  /// 创建工作薄
  Sheet sheetObject = excel['MoodExample'];

  /// 设置默认工作薄
  excel.setDefaultSheet('MoodExample');

  /// 单元格样式
  CellStyle cellStyle = CellStyle(
    fontColorHex: "#FFFFFF",
    fontSize: 10,
    bold: true,
    fontFamily: getFontFamily(FontFamily.Microsoft_Sans_Serif),
    backgroundColorHex: "#3E4663",
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  /// 创建大标题
  sheetObject.merge(
    CellIndex.indexByString("A1"),
    CellIndex.indexByString("E1"),
  );
  sheetObject.cell(CellIndex.indexByString("A1"))
    ..value = "MoodExample"
    ..cellStyle = CellStyle(
      fontColorHex: "#FFFFFF",
      fontSize: 10,
      bold: true,
      fontFamily: getFontFamily(FontFamily.Microsoft_Sans_Serif),
      backgroundColorHex: "#3E4663",
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

  /// 创建字段标题
  sheetObject.cell(CellIndex.indexByString("A2"))
    ..value = "表情"
    ..cellStyle = cellStyle.copyWith(
        fontFamilyVal: getFontFamily(FontFamily.Apple_Color_Emoji));
  sheetObject.cell(CellIndex.indexByString("B2"))
    ..value = "心情"
    ..cellStyle = cellStyle;
  sheetObject.cell(CellIndex.indexByString("C2"))
    ..value = "内容"
    ..cellStyle = cellStyle;
  sheetObject.cell(CellIndex.indexByString("D2"))
    ..value = "心情程度"
    ..cellStyle = cellStyle;
  sheetObject.cell(CellIndex.indexByString("E2"))
    ..value = "创建时间"
    ..cellStyle = cellStyle;

  /// 添加Excel数据
  sheetObject.appendRow(["😊", "开心", "今天很开心", 55, "2000-11-03"]);

  /// 保存Excel
  final fileBytes = excel.save();

  /// 存入文件
  File(join(fileName))
    ..createSync(recursive: true)
    ..writeAsBytesSync(fileBytes!);

  return fileName;
}

/// 导入数据
Future<Map> importDatabase(BuildContext context) async {
  print("导入数据");
  Map _returnResults = {
    "state": null, // 状态，0: 有错误 1: 导入成功
    "errorPath": "", // 错误文件位置
  };
  try {
    /// 清除选择文件的缓存
    await FilePicker.platform.clearTemporaryFiles();

    /// 选择文件
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );
    if (result != null) {
      /// 文件路径、内容
      final file = result.files.single.path ?? '';
      final bytes = File(file).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      for (final table in excel.tables.keys) {
        print(table); // 工作表名
        print(excel.tables[table]!.maxCols); // 表最大列数
        print(excel.tables[table]!.maxRows); // 表最大行数
        /// 判断是否是需要的工作表
        if (table == "MoodExample") {
          /// 检测导入表是否符合标准，否则导出错误提示的Excel文件
          final _errorPath =
              await importDatabaseError(excel.tables['MoodExample']!.rows);
          print("错误文件" + _errorPath);

          if (_errorPath.isNotEmpty) {
            _returnResults["state"] = 0;
            _returnResults["errorPath"] = _errorPath;
          } else {
            /// 导入数据操作
            await importDatabaseStart(excel.tables['MoodExample']!.rows);
            _returnResults["state"] = 1;
          }
        }
      }
    } else {
      /// 未选择文件
    }
  } catch (e) {
    print(e);
  }
  return _returnResults;
}

/// 正式导入数据
Future importDatabaseStart(List<List<Data?>> database) async {
  /// 心情数据
  Map<String, dynamic> _moodData = {
    "icon": "",
    "title": "",
    "score": 50,
    "content": null,
    "createTime": "",
    "updateTime": ""
  };
  int _dataIndex = 0;
  for (final row in database) {
    for (final data in row) {
      _dataIndex++;
      if (_dataIndex < 3) {
        break;
      }
      int? colIndex = data?.colIndex;
      dynamic value = data?.value;
      switch (colIndex) {

        /// 表情
        case 0:
          _moodData["icon"] = value.toString();
          break;

        /// 心情
        case 1:
          _moodData["title"] = value.toString();
          break;

        /// 内容
        case 2:
          _moodData["content"] = value.toString();
          break;

        /// 心情程度
        case 3:
          _moodData["score"] = double.parse(value.toString()).toInt();
          break;

        /// 创建日期、修改日期
        case 4:
          final _moodDate =
              DateFormat("yyyy-MM-dd").parse(value).toString().substring(0, 10);
          _moodData["createTime"] = _moodDate;
          _moodData["updateTime"] = _moodDate;
          break;
      }

      /// 导入数据（一组数据完成）
      if (colIndex == 4) {
        print(moodDataFromJson(json.encode(_moodData)));

        /// 是否操作成功
        late bool _result = false;
        _result = await MoodService.addMoodData(
            moodDataFromJson(json.encode(_moodData)));
        print("是否导入成功" + _result.toString());
      }
    }
  }
}

/// 导入数据错误处理
Future<String> importDatabaseError(List<List<Data?>> database) async {
  String _errorPath = "";
  final _errorData = await importDatabaseErrorCheck(database);

  /// 存在错误就开始存储错误文件
  if (_errorData.isNotEmpty) {
    DateTime now = DateTime.now();

    /// 获取APP文件临时根路径
    final directory = (await getTemporaryDirectory()).path;

    /// 保存文件路径及名称
    final String filePath = "$directory/system/database/importError";
    final String fileName = "$filePath/MoodExample导入错误内容_$now.xlsx";

    /// 删除之前的缓存
    try {
      Directory(filePath).deleteSync(recursive: true);
    } catch (e) {
      print(e);
    }

    /// 创建Excel
    Excel excelError = Excel.createExcel();

    /// 创建工作薄
    Sheet sheetObject = excelError['MoodExample'];

    /// 设置默认工作薄
    excelError.setDefaultSheet('MoodExample');

    /// 单元格样式
    CellStyle cellStyle = CellStyle(
      fontColorHex: "#FFFFFF",
      fontSize: 10,
      bold: true,
      fontFamily: getFontFamily(FontFamily.Microsoft_Sans_Serif),
      backgroundColorHex: "#3E4663",
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    /// 创建大标题
    sheetObject.merge(
      CellIndex.indexByString("A1"),
      CellIndex.indexByString("B1"),
    );
    sheetObject.cell(CellIndex.indexByString("A1"))
      ..value = "MoodExample"
      ..cellStyle = CellStyle(
        fontColorHex: "#FFFFFF",
        fontSize: 10,
        bold: true,
        fontFamily: getFontFamily(FontFamily.Microsoft_Sans_Serif),
        backgroundColorHex: "#3E4663",
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

    /// 创建字段标题
    sheetObject.cell(CellIndex.indexByString("A2"))
      ..value = "错误所在行"
      ..cellStyle = cellStyle.copyWith(
          fontFamilyVal: getFontFamily(FontFamily.Apple_Color_Emoji));
    sheetObject.cell(CellIndex.indexByString("B2"))
      ..value = "错误内容"
      ..cellStyle = cellStyle;

    /// 添加Excel数据
    for (var list in _errorData) {
      sheetObject.appendRow(list);
    }

    /// 保存Excel
    final fileBytes = excelError.save();

    /// 存入文件
    File(join(fileName))
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);

    _errorPath = fileName;
  }
  return _errorPath;
}

/// 导入数据错误检测
Future<List<List>> importDatabaseErrorCheck(List<List<Data?>> database) async {
  /// 错误内容
  List<List> _errorData = [];

  /// 错误原因
  String _errorText = "";

  int _dataIndex = 0;
  int _rowIndex = 0;
  for (final row in database) {
    _dataIndex++;
    if (_dataIndex < 3) {
      continue;
    }
    for (final data in row) {
      dynamic value = data?.value;
      // print(data);
      // print(value);
      // print(_rowIndex);
      switch (_rowIndex) {

        /// 表情
        case 0:
          if (value == null) {
            _errorText += "【表情必填】 ";
          }
          break;

        /// 心情
        case 1:
          if (value == null) {
            _errorText += "【心情必填】 ";
          }
          break;

        /// 内容
        case 2:
          break;

        /// 心情程度
        case 3:
          final _tryValue = double.tryParse(value.toString()) == null
              ? null
              : double.parse(value.toString()).toInt();
          if (_tryValue == null) {
            _errorText += "【心情程度只能为0-100整数】 ";
          }
          if (_tryValue != null && (_tryValue < 0 || _tryValue > 100)) {
            _errorText += "【心情程度只能为0-100整数】 ";
          }
          break;

        /// 创建日期、修改日期
        case 4:
          String? _tryValue;
          try {
            _tryValue = DateFormat("yyyy-MM-dd")
                .parse(value)
                .toString()
                .substring(0, 10);
          } catch (e) {
            _tryValue = null;
          }
          print(_tryValue);
          if (_tryValue == null) {
            _errorText += "【创建时间只能为文本，如2000-11-03】 ";
          }
          break;
      }

      /// 导入数据（一组数据完成）并且错误内容不为空
      if (_rowIndex == 4 && _errorText.isNotEmpty) {
        print("一组数据");
        _errorData.add(["第$_dataIndex行", _errorText]);
      }

      /// 重置
      if (_rowIndex == 4) {
        _rowIndex = -1;

        /// 错误原因
        _errorText = "";
      }

      _rowIndex++;
    }
  }

  return _errorData;
}

/// 导出数据
class ExportDatabaseBody extends StatefulWidget {
  const ExportDatabaseBody({Key? key}) : super(key: key);

  @override
  State<ExportDatabaseBody> createState() => _ExportDatabaseBodyState();
}

class _ExportDatabaseBodyState extends State<ExportDatabaseBody> {
  /// 数据导出位置
  String _exportPath = "";

  /// 数据是否正在导出
  bool _isExport = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 128.h,
          height: 128.h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withAlpha(140),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  offset: const Offset(0, 5.0),
                  blurRadius: 15.0,
                  spreadRadius: 2.0,
                )
              ],
              shape: BoxShape.circle,
            ),
            child: _isExport
                ? CupertinoActivityIndicator(
                    radius: 14.sp,
                    color: const Color(0xFFFFFFFF),
                  )
                : Material(
                    color: Colors.transparent,
                    child: IconButton(
                      splashColor: Colors.white10,
                      highlightColor: Colors.white10,
                      icon: const Icon(Remix.arrow_down_line),
                      iconSize: 48.sp,
                      color: const Color(0xFFFFFFFF),
                      padding: EdgeInsets.all(22.w),
                      onPressed: () async {
                        vibrate();
                        try {
                          /// 没文件则进行生成
                          if (_exportPath.isEmpty) {
                            setState(() {
                              _isExport = true;
                            });
                            await Future.delayed(
                                const Duration(milliseconds: 1000), () async {
                              _exportPath = await exportDatabase();
                            });
                          }

                          /// 有文件则直接分享
                          if (_exportPath.isNotEmpty) {
                            setState(() {
                              _isExport = false;
                            });
                            vibrate();
                            Fluttertoast.showToast(
                              msg: S
                                  .of(context)
                                  .app_setting_database_export_data_toast_success,
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.black54,
                              textColor: Colors.white,
                              fontSize: 12.sp,
                            );

                            /// 分享文件
                            Share.shareFiles([_exportPath]);
                          }
                        } catch (e) {
                          print(e);
                        }
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// 导出数据
Future<String> exportDatabase() async {
  MoodViewModel moodViewModel = MoodViewModel();
  DateTime now = DateTime.now();

  /// 获取APP文件临时根路径
  final directory = (await getTemporaryDirectory()).path;

  /// 保存文件路径及名称
  final String filePath = "$directory/system/database/export";
  final String fileName = "$filePath/MoodExample_$now.xlsx";

  /// 删除之前的缓存
  try {
    Directory(filePath).deleteSync(recursive: true);
  } catch (e) {
    print(e);
  }

  /// 创建Excel
  Excel excel = Excel.createExcel();

  /// 创建工作薄
  Sheet sheetObject = excel['MoodExample'];

  /// 设置默认工作薄
  excel.setDefaultSheet('MoodExample');

  /// 单元格样式
  CellStyle cellStyle = CellStyle(
    fontColorHex: "#FFFFFF",
    fontSize: 10,
    bold: true,
    fontFamily: getFontFamily(FontFamily.Microsoft_Sans_Serif),
    backgroundColorHex: "#3E4663",
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  /// 创建大标题
  sheetObject.merge(
    CellIndex.indexByString("A1"),
    CellIndex.indexByString("F1"),
  );
  sheetObject.cell(CellIndex.indexByString("A1"))
    ..value = "MoodExample"
    ..cellStyle = CellStyle(
      fontColorHex: "#FFFFFF",
      fontSize: 10,
      bold: true,
      fontFamily: getFontFamily(FontFamily.Microsoft_Sans_Serif),
      backgroundColorHex: "#3E4663",
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

  /// 创建字段标题
  sheetObject.cell(CellIndex.indexByString("A2"))
    ..value = "表情"
    ..cellStyle = cellStyle.copyWith(
        fontFamilyVal: getFontFamily(FontFamily.Apple_Color_Emoji));
  sheetObject.cell(CellIndex.indexByString("B2"))
    ..value = "心情"
    ..cellStyle = cellStyle;
  sheetObject.cell(CellIndex.indexByString("C2"))
    ..value = "内容"
    ..cellStyle = cellStyle;
  sheetObject.cell(CellIndex.indexByString("D2"))
    ..value = "心情程度"
    ..cellStyle = cellStyle;
  sheetObject.cell(CellIndex.indexByString("E2"))
    ..value = "创建时间"
    ..cellStyle = cellStyle;
  sheetObject.cell(CellIndex.indexByString("F2"))
    ..value = "修改时间"
    ..cellStyle = cellStyle;

  /// 获取所有心情数据并赋值
  await MoodService.getMoodAllData(moodViewModel);
  final _moodAllDataList = moodViewModel.moodAllDataList;

  /// 添加Excel数据
  _moodAllDataList?.forEach((list) {
    List dataList = [
      list.icon,
      list.title,
      list.content,
      list.score,
      list.createTime,
      list.updateTime,
    ];

    sheetObject.appendRow(dataList);
  });

  /// 保存Excel
  final fileBytes = excel.save();

  /// 存入文件
  File(join(fileName))
    ..createSync(recursive: true)
    ..writeAsBytesSync(fileBytes!);

  return fileName;
}
