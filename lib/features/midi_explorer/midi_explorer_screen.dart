import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../midi/midi_device.dart';
import '../../midi/midi_packet.dart';
import 'midi_explorer_controller.dart';

class MidiExplorerScreen extends ConsumerStatefulWidget {
  const MidiExplorerScreen({super.key});

  @override
  ConsumerState<MidiExplorerScreen> createState() => _MidiExplorerScreenState();
}

class _MidiExplorerScreenState extends ConsumerState<MidiExplorerScreen> {
  late final MidiExplorerController _controller;
  final _messageController = TextEditingController(text: 'B0 4A 64');
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ref.read(midiExplorerControllerProvider)
      ..addListener(_onChanged);
    _controller.start();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _messageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SEQTRAK MIDI Explorer')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final devicePanel = _DevicePanel(controller: _controller);
            final recordingPanel = _RecordingPanel(
              controller: _controller,
              notesController: _notesController,
            );
            final monitor = _Monitor(controller: _controller);
            if (constraints.maxWidth >= 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 320,
                    child: SingleChildScrollView(
                      child: Column(children: [devicePanel, recordingPanel]),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: monitor),
                ],
              );
            }
            return Column(
              children: [
                devicePanel,
                recordingPanel,
                const Divider(height: 1),
                Expanded(child: monitor),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _SendBar(
        controller: _controller,
        textController: _messageController,
      ),
    );
  }
}

class _DevicePanel extends StatelessWidget {
  const _DevicePanel({required this.controller});

  final MidiExplorerController controller;

  @override
  Widget build(BuildContext context) {
    final connected = controller.connectedDevice;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('MIDI devices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Refresh devices',
              onPressed: controller.isBusy ? null : controller.refreshDevices,
              icon: const Icon(Icons.refresh),
            ),
          ),
          if (controller.devices.isEmpty)
            const Text('No MIDI devices found')
          else
            for (final device in controller.devices)
              _DeviceTile(
                device: device,
                connected: device == connected,
                busy: controller.isBusy,
                onConnect: () => controller.connect(device),
                onDisconnect: controller.disconnect,
              ),
          if (controller.error case final error?) ...[
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordingPanel extends StatelessWidget {
  const _RecordingPanel({
    required this.controller,
    required this.notesController,
  });

  final MidiExplorerController controller;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Capture', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Experiment notes',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: controller.isRecording
                    ? controller.stopRecording
                    : controller.startRecording,
                icon: Icon(
                  controller.isRecording
                      ? Icons.stop
                      : Icons.fiber_manual_record,
                ),
                label: Text(controller.isRecording ? 'Stop' : 'Record'),
              ),
              OutlinedButton.icon(
                onPressed:
                    controller.recordedPacketCount == 0 || controller.isBusy
                    ? null
                    : () =>
                          controller.exportCapture(notes: notesController.text),
                icon: const Icon(Icons.save_alt),
                label: const Text('Export'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.isRecording
                ? 'Recording ${controller.recordedPacketCount} messages'
                : '${controller.recordedPacketCount} recorded messages',
          ),
          if (controller.lastExportPath case final path?)
            Text(
              'Saved to $path',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.connected,
    required this.busy,
    required this.onConnect,
    required this.onDisconnect,
  });

  final MidiDevice device;
  final bool connected;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(connected ? Icons.usb : Icons.usb_off),
      title: Text(device.name),
      subtitle: Text(connected ? 'Connected' : device.type.name),
      trailing: TextButton(
        onPressed: busy ? null : (connected ? onDisconnect : onConnect),
        child: Text(connected ? 'Disconnect' : 'Connect'),
      ),
    );
  }
}

class _Monitor extends StatelessWidget {
  const _Monitor({required this.controller});

  final MidiExplorerController controller;

  @override
  Widget build(BuildContext context) {
    final visiblePackets = controller.visiblePackets;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Traffic', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    selected: controller.showRealtimeNoise,
                    onSelected: controller.setShowRealtimeNoise,
                    label: const Text('Show clock/sensing'),
                    tooltip:
                        'Show F8 Timing Clock and FE Active Sensing messages',
                  ),
                  TextButton.icon(
                    onPressed: visiblePackets.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: controller.formatVisibleTraffic(),
                              ),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Visible traffic copied'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy traffic'),
                  ),
                  TextButton.icon(
                    onPressed: controller.packets.isEmpty
                        ? null
                        : controller.clearLog,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: visiblePackets.isEmpty
              ? Center(
                  child: Text(
                    controller.packets.isEmpty
                        ? 'MIDI traffic will appear here'
                        : 'Only hidden clock or active-sensing messages received',
                  ),
                )
              : SelectionArea(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: visiblePackets.length,
                    itemBuilder: (context, index) {
                      final packet =
                          visiblePackets[visiblePackets.length - index - 1];
                      return _PacketTile(
                        packet: packet,
                        controller: controller,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _PacketTile extends StatelessWidget {
  const _PacketTile({required this.packet, required this.controller});

  final MidiPacket packet;
  final MidiExplorerController controller;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        controller.formatPacket(packet),
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}

class _SendBar extends StatelessWidget {
  const _SendBar({required this.controller, required this.textController});

  final MidiExplorerController controller;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Hexadecimal MIDI bytes',
                    hintText: 'F0 43 ... F7',
                  ),
                  onSubmitted: controller.connectedDevice == null
                      ? null
                      : controller.sendHex,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed:
                    controller.connectedDevice == null || controller.isBusy
                    ? null
                    : () => controller.sendHex(textController.text),
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
