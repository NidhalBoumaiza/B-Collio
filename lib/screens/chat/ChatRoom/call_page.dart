// lib/screens/chat/ChatRoom/call_page.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import '../../../controllers/call_service_controller.dart';
import 'package:get/get.dart';

class CallPage extends StatefulWidget {
  final String localUserID;
  final String localUserName;
  final String targetUserID;
  final String targetUserName;
  final String roomID;
  final bool isVideoCall;

  const CallPage({
    super.key,
    required this.localUserID,
    required this.localUserName,
    required this.targetUserID,
    required this.targetUserName,
    required this.roomID,
    required this.isVideoCall,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  Widget? localView;
  int? localViewID;
  Widget? remoteView;
  int? remoteViewID;
  final CallServiceController callController =
      Get.find<CallServiceController>();

  @override
  void initState() {
    super.initState();
    log('initState-------------------call   page ------ ${widget.roomID} ==${widget.localUserID}----');
    startListenEvent();
    loginRoom();
  }

  @override
  void dispose() {
    stopListenEvent();
    logoutRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              "${widget.isVideoCall ? 'Video' : 'Voice'} Call with ${widget.targetUserName}")),
      body: Stack(
        children: [
          localView ?? const SizedBox.shrink(),
          Positioned(
            top: MediaQuery.of(context).size.height / 20,
            right: MediaQuery.of(context).size.width / 20,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: AspectRatio(
                aspectRatio: 9.0 / 16.0,
                child: remoteView ??
                    Container(color: Colors.black.withOpacity(0.2)),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 20,
            left: 0,
            right: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              height: MediaQuery.of(context).size.width / 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context),
                    child: const Center(child: Icon(Icons.call_end, size: 32)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loginRoom() async {
    final user = ZegoUser(widget.localUserID, widget.localUserName);
    ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig()
      ..isUserStatusNotify = true;
    log('loginRoom-------------------call   page ------ ${widget.roomID} ==${widget.localUserID}----');
    await ZegoExpressEngine.instance
        .loginRoom(widget.roomID, user, config: roomConfig)
        .then((result) {
      if (result.errorCode == 0) {
        log('loginRoom-------------------call   page -----${result.errorCode}----');
        startPreview();
        startPublish();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${result.errorCode}')),
        );
      }
    });
  }

  Future<void> logoutRoom() async {
    stopPreview();
    stopPublish();
    await ZegoExpressEngine.instance.logoutRoom(widget.roomID);
  }

  void startListenEvent() {
    log('startListenEvent-----------------------------');
    try {
      ZegoExpressEngine.onRoomUserUpdate = callController.onRoomUserUpdate;
      log('startListenEvent---111111--------------------------');
      ZegoExpressEngine.onRoomStreamUpdate =
          (roomID, updateType, List<ZegoStream> streamList, extendedData) {
        if (updateType == ZegoUpdateType.Add) {
          log('startListenEvent-------------updateType----------------');
          for (final stream in streamList) {
            startPlayStream(stream.streamID);
          }
        } else {
          log('startListenEvent-------------else updateType----------------');
          for (final stream in streamList) {
            stopPlayStream(stream.streamID);
          }
        }
      };
      ZegoExpressEngine.onRoomStateUpdate =
          (roomID, state, errorCode, extendedData) {
        log('onRoomStateUpdate: $roomID, $state, $errorCode');
      };
      ZegoExpressEngine.onPublisherStateUpdate =
          (streamID, state, errorCode, extendedData) {
        log('onPublisherStateUpdate: $streamID, $state, $errorCode');
      };
    } catch (e) {
      debugPrint('Error in startListenEven_________________: $e');
    }
  }

  void stopListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;
  }

  Future<void> startPreview() async {
    log('startPreview-----func--------------call page ------ ${widget.roomID} ==${widget.localUserID}----');

    if (widget.isVideoCall) {
      // Pour les appels vidéo, créer la vue normalement
      try {
        await ZegoExpressEngine.instance.createCanvasView((viewID) async {
          localViewID = viewID;
          ZegoCanvas previewCanvas =
              ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
          await ZegoExpressEngine.instance.startPreview(
              canvas: previewCanvas, channel: ZegoPublishChannel.Main);
        }).then((canvasViewWidget) {
          setState(() => localView = canvasViewWidget);
        }).catchError((error) {
          log('Error in video preview: $error');
        });
      } catch (e) {
        log('Error in video startPreview: $e');
      }
    } else {
      // Pour les appels vocaux, pas besoin de créer une vue
      setState(() => localView = Container()); // Vue vide

      // S'assurer que la vidéo est désactivée pour les appels vocaux
      try {
        await ZegoExpressEngine.instance
            .mutePublishStreamVideo(true, channel: ZegoPublishChannel.Main);
        log('Video muted for voice call');
      } catch (e) {
        log('Error muting video: $e');
      }
    }
  }

  Future<void> stopPreview() async {
    ZegoExpressEngine.instance.stopPreview(channel: ZegoPublishChannel.Main);
    if (localViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(localViewID!);
      if (mounted) setState(() => localView = null);
    }
  }

  Future<void> startPublish() async {
    try {
      String streamID = '${widget.roomID}_${widget.localUserID}_call';
      log('streamID-------------------call   page ------ ${widget.roomID} ==${widget.localUserID}----');
      await ZegoExpressEngine.instance
          .startPublishingStream(streamID, channel: ZegoPublishChannel.Main)
          .then((value) {
        log('srt=============');
      }).onError((error, stackTrace) {
        log('Error in startPublish: $error');
      });

      if (callController.incomingCallData != null &&
          callController.incomingCallData!['conversation_id'] ==
              widget.roomID) {
        callController.incomingCallData!['is_video_call'] = widget.isVideoCall;
      }
    } catch (e) {
      debugPrint('Error in startPublish: $e');
    }
  }

  Future<void> stopPublish() async {
    await ZegoExpressEngine.instance
        .stopPublishingStream(channel: ZegoPublishChannel.Main);
  }

  Future<void> startPlayStream(String streamID) async {
    try {
      await ZegoExpressEngine.instance.createCanvasView((viewID) {
        remoteViewID = viewID;
        ZegoCanvas canvas =
            ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
        ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
      }).then((canvasViewWidget) {
        setState(() => remoteView = canvasViewWidget);
      });
      if (!widget.isVideoCall) {
        ZegoExpressEngine.instance.mutePlayStreamVideo(streamID, true);
      }
    } catch (e) {
      debugPrint('Error in startPlayStream: $e');
    }
  }

  Future<void> stopPlayStream(String streamID) async {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
    if (remoteViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(remoteViewID!);
      if (mounted) setState(() => remoteView = null);
    }
  }
}
