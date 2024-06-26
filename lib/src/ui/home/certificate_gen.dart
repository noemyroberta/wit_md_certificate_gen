import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:certificate_generator/src/ui/home/components/certificate_viewer.dart';
import 'package:certificate_generator/src/ui/home/components/font_settings/font_settings_entity.dart';
import 'package:certificate_generator/src/ui/home/components/font_settings/font_settings_section.dart';
import 'package:certificate_generator/src/ui/home/components/generator.dart';
import 'package:certificate_generator/src/ui/widgets/colors.dart';
import 'package:certificate_generator/src/ui/widgets/draggable_text.dart';
import 'package:certificate_generator/src/ui/widgets/file_section.dart';
import 'package:certificate_generator/src/ui/widgets/strings.dart';

import 'components/header.dart';

class CertificateGen extends StatefulWidget {
  const CertificateGen({super.key});

  @override
  State<CertificateGen> createState() => _CertificateGenState();
}

class _CertificateGenState extends State<CertificateGen> {
  Uint8List? imageBytes;
  String imageName = '';
  GlobalKey? imageKey;
  GlobalKey viewerKey = GlobalKey();
  Offset position = const Offset(0, 0);
  String initialText = "";
  Map<int, FontSettingsEntity> header = {};
  List<List<String>> rows = [];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return MaterialApp(
      title: 'WIT Certificate Gen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: size.height * 0.1,
                width: double.infinity,
                child: const ColoredBox(
                  color: primaryColor,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Header(),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.2),
              Container(
                color: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 120),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: size.width * 0.5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FileSection(
                            title: backgroundTitleText,
                            subtitle: backgroundSubtitleText,
                            buttonIcon: Icons.photo,
                            buttonTitle: 'Insira o fundo',
                            onPressed: _uploadImage,
                            gettedFileName: imageName,
                          ),
                          const SizedBox(height: 50),
                          FileSection(
                            title: csvTitleText,
                            subtitle: csvSubtitleText,
                            buttonIcon: Icons.file_upload,
                            buttonTitle: 'Insira o arquivo CSV',
                            onPressed: _uploadFile,
                          ),
                          const SizedBox(height: 50),
                          Visibility(
                            visible: header.isNotEmpty,
                            child: FontSettingsSection(
                              initialText: initialText,
                              header: header,
                              onTextChanged: (text) {
                                setState(() {
                                  header.update(text.$1, (value) => text.$2);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    CertificateViewer(
                      key: viewerKey,
                      imageKey: (key) => imageKey = key,
                      imageBytes: imageBytes,
                      imageName: imageName,
                      onDownload: () async {
                        final gen = Generator(
                          context: context,
                          csv: rows,
                          background: imageBytes!,
                          settings: header.values.toList(),
                        );
                        await gen.create();
                      },
                      texts: header.isEmpty
                          ? []
                          : header.entries.map((entry) {
                              int index = entry.key;
                              final setting = entry.value;

                              return DraggableText(
                                imageKey: imageKey!,
                                aereaKey: viewerKey,
                                onPositionedText: (offset) {
                                  position = offset;
                                  header.values.elementAt(index).position =
                                      offset;
                                },
                                fontSize: _getFontSizeByPos(index),
                                fontColor: _getColorByPos(index),
                                text: getWithNoSpaceAtTheEnd(setting.value),
                              );
                            }).toList(),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String getWithNoSpaceAtTheEnd(String text) {
    if (text.endsWith(' ')) {
      String value = text.substring(0, text.length - 1);
      return value;
    }
    return text;
  }

  void _uploadImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'svg', 'jpeg']);

    if (result != null) {
      final bytes = result.files.first.bytes;
      final name = result.files.first.name;
      setState(() {
        imageBytes = bytes;
        imageName = name;
      });
    }
  }

  void _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['csv']);

    if (result != null) {
      PlatformFile file = result.files.first;
      Uint8List fileBytes = file.bytes!;
      String content = utf8.decode(fileBytes);
      rows = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: "\n",
      ).convert<String>(content, eol: "\n", shouldParseNumbers: false);
      _initializeFontSettings(rows[0]);
    }
  }

  void _initializeFontSettings(List<String> csvHeader) {
    if (csvHeader.isEmpty) {
      return;
    }

    for (int i = 0; i < csvHeader.length; i++) {
      header[i] = FontSettingsEntity(
        csvHeader[i],
        fontSize: 20,
        color: Colors.black87,
      );
    }

    setState(() {
      initialText = "#1 ${header[0]!.value}";
    });
  }

  int? _getFontSizeByPos(int position) {
    for (final setting in header.entries) {
      if (setting.key == position) {
        return setting.value.fontSize;
      }
    }
    return null;
  }

  Color? _getColorByPos(int position) {
    for (var setting in header.entries) {
      if (setting.key == position) {
        return setting.value.color;
      }
    }
    return null;
  }
}
