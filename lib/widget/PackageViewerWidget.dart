import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:untitled6/DiscordDataType.dart';

class PackageViewerWidget extends StatefulWidget {
  const PackageViewerWidget({
    Key? key,
    required this.package,
    required this.path,
  }) : super(key: key);

  final Map<String, dynamic> package;
  final String path;

  @override
  _PackageViewerWidgetState createState() => _PackageViewerWidgetState();
}

class _PackageViewerWidgetState extends State<PackageViewerWidget> {
  @override
  void initState() {
    super.initState();
    setState(() {
      _loading = _loadFiles();
    });
  }

  Guild? curentGuild;
  Channel? currentChannel;

  late types.User currentUser;
  late Stream<Map<String, double>> _loading;
  Future<List<DiscordMessage>>? messagesLoading;

  Future<File?> downloadMedia(Uri url) async {
    final Directory dir = Directory('${Directory.current.path}/${url.host}');
    if (!dir.existsSync()) {
      dir.createSync();
    }
    final file = File('${dir.path}/${url.path.replaceAll("/", "-")}');

    if (!file.existsSync()) {
      final http = await HttpClient().getUrl(url);
      final response = await http.close();
      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes, flush: true);
        return file;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    currentUser = types.User(
      id: widget.package['id'],
      firstName: widget.package['username'],
    );
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.package['username']),
        ),
        body: StreamBuilder<Map<String, double>>(
            stream: _loading,
            builder: (context, snapshot) {
              String message;
              double? progress;
              if (snapshot.hasData) {
                message = snapshot.data?.keys.first ?? 'Loading...';
                progress = snapshot.data?.values.first;
              } else if (snapshot.hasError) {
                message = 'Error: ${snapshot.error}';
                progress = null;
              } else {
                message = 'Loading...';
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                    child: Column(
                  children: [
                    Text(message),
                    LinearProgressIndicator(value: progress),
                  ],
                ));
              }
              return Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.05,
                    height: MediaQuery.of(context).size.height,
                    child: ListView.builder(
                        itemCount: _guilds.length,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          Guild g = _guilds.values.toList()[index];
                          Guild guild = g;
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.05,
                            height: MediaQuery.of(context).size.height * 0.07,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 0, 0, 4),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  primary: guild == curentGuild
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    curentGuild = guild;
                                    if (guild.channels.length == 1) {
                                      _setCurrentChannel(guild.channels.first);
                                    }
                                  });
                                },
                                child: Text(guild.getShortName()),
                              ),
                            ),
                          );
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: MediaQuery.of(context).size.height * 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  if (curentGuild != null)
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 0, 0, 16),
                                      child: Text(
                                        curentGuild!.name,
                                      ),
                                    ),
                                  if (curentGuild != null)
                                    for (final channels
                                        in curentGuild!.channels)
                                      MaterialButton(
                                        onPressed: () {
                                          setState(() {
                                            _setCurrentChannel(channels);
                                          });
                                        },
                                        color: currentChannel == channels
                                            ? Colors.blue
                                            : Colors.white,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(0, 0, 4, 0),
                                              child: Icon(
                                                Icons.tag,
                                                color: Colors.black,
                                                size: 24,
                                              ),
                                            ),
                                            Text(
                                              channels.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.05,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                MaterialButton(
                                  child: CircleAvatar(
                                    backgroundImage: FileImage(File(
                                        "${widget.path}/account/avatar.png")),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                Text(
                                  '${widget.package['username']}#${widget.package['discriminator']}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (messagesLoading != null)
                    Expanded(
                      child: FutureBuilder(
                          future: messagesLoading,
                          builder: (BuildContext context,
                              AsyncSnapshot<List<DiscordMessage>> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              List<DiscordMessage> messages =
                                  snapshot.data ?? [];
                              return SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    for (final message in messages)
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0, 0, 0, 12),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.1,
                                              child: Text(
                                                "${message.timestamp.year}/${message.timestamp.month}/${message.timestamp.day} ${message.timestamp.hour}:${message.timestamp.minute}:${message.timestamp.second}:  ",
                                              ),
                                            ),
                                            Container(
                                              color: Colors.cyanAccent,
                                              child: Text(
                                                message.content ?? '',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (message.attachments.isNotEmpty)
                                              Column(
                                                children: [
                                                  for (final attachment
                                                      in message.attachments)
                                                    Column(
                                                      children: [
                                                        Text(
                                                          attachment.toString(),
                                                        ),
                                                        FutureBuilder<File?>(
                                                          future: downloadMedia(
                                                              attachment),
                                                          builder: (context,
                                                              snapshot) {
                                                            if (snapshot.connectionState ==
                                                                    ConnectionState
                                                                        .done &&
                                                                snapshot.data !=
                                                                    null) {
                                                              File file =
                                                                  snapshot
                                                                      .data!;
                                                              return Image.file(
                                                                  file,
                                                                  errorBuilder: (BuildContext
                                                                          context,
                                                                      Object
                                                                          error,
                                                                      StackTrace?
                                                                          stackTrace) {
                                                                return Container();
                                                              },
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.4,
                                                                  height: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .height *
                                                                      0.4);
                                                            }
                                                            return const LinearProgressIndicator();
                                                          },
                                                        ),
                                                      ],
                                                    )
                                                ],
                                              )
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          }),
                    ),
                ],
              );
            }));
  }

  final Map<String, Guild> _guilds = {};

  Stream<Map<String, double>> _loadFiles() async* {
    //traverse directory
    // messages/ and servers/ to read metadata
    Directory messagesDir = Directory('${widget.path}/messages');
    Directory serversDir = Directory('${widget.path}/servers');
    final serversDirs =
        await serversDir.list().where((event) => event is Directory).toList();

    for (int i = 0; i < serversDirs.length; i++) {
      final event = serversDirs[i];
      double progress = (i / serversDirs.length);
      yield {'Reading Server Name': progress};
      try {
        final guildDir = Directory(event.path);
        final metadataFile = File('${guildDir.path}/guild.json');
        if (!await metadataFile.exists()) continue;
        final metadata = json.decode(metadataFile.readAsStringSync());
        final g = Guild(metadata['id'], metadata['name']);
        _guilds[g.id] = g;
      } catch (e) {
        print(e);
      }
    }

    //read channel.json in messages
    final messageDirs =
        await messagesDir.list().where((event) => event is Directory).toList();
    for (int j = 0; j < messageDirs.length; j++) {
      final event = messageDirs[j];
      double progress = (j / messageDirs.length);
      yield {'Reading Channel Data': progress};
      try {
        final channelDir = Directory(event.path);
        final metadataFile = File('${channelDir.path}/channel.json');
        final csvFile = File('${channelDir.path}/messages.csv');
        if (!await metadataFile.exists()) continue;
        if (!await csvFile.exists()) continue;
        Map<String, dynamic> metadata =
            json.decode(metadataFile.readAsStringSync());
        try {
          String name;
          String id;
          String guildID;
          if (metadata.length == 2) {
            id = metadata['id'];
            name = metadata['id'];
            guildID = metadata['id'];
          } else if (metadata.length == 3 && metadata['type'] == 1) {
            name = metadata['recipients'].join("+");
            guildID = metadata['id'];
            id = guildID;
          } else if (metadata['type'] == 3) {
            name = metadata['name'] ?? metadata['id'];
            guildID = metadata['id'];
            id = guildID;
          } else {
            id = metadata['id'];
            name = metadata['name'];
            guildID = metadata['guild']['id'];
          }
          final channel = Channel(id, name, csvFile.path);
          Guild? guild = _guilds[guildID];
          if (guild == null) {
            guild = Guild(channel.id, channel.name);
            _guilds[channel.id] = guild;
          }
          guild.channels.add(channel);
        } catch (e) {
          print(e);
        }
      } catch (e) {
        print(e);
      }
    }
    //remove guilds that have no channels
    _guilds.removeWhere((key, value) => value.channels.isEmpty);
    yield {"Finished": 1.0};
  }

  void _setCurrentChannel(Channel channels) {
    currentChannel = channels;
    messagesLoading = channels.getMessages();
  }
}
