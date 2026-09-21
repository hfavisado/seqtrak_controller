import 'package:flutter/material.dart';

import '../../midi/midi_device.dart';
import '../../midi/midi_packet.dart';
import '../../midi/midi_transport.dart';
import 'midi_explorer_controller.dart';

class MidiExplorerScreen extends StatefulWidget {
  const MidiExplorerScreen({required this.transport, super.key});

  final MidiTransport transport;

  @override
  State<MidiExplorerScreen> createState() => _MidiExplorerScreenState();
}

class _MidiExplorerScreenState extends State<MidiExplorerScreen> {
  late final MidiExplorerController _controller;
  final _messageController = TextEditingController(text: 'B0 4A 64');

  @override
  void initState() {
    super.initState();
    _controller = MidiExplorerController(transport: widget.transport)
      ..addListener(_onChanged);
    _controller.start();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _messageController.dispose();
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
            final monitor = _Monitor(controller: _controller);
            if (constraints.maxWidth >= 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 320, child: devicePanel),
                  const VerticalDivider(width: 1),
                  Expanded(child: monitor),
                ],
              );
            }
            return Column(
              children: [
                devicePanel,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Traffic',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
        ),
        Expanded(
          child: controller.packets.isEmpty
              ? const Center(child: Text('MIDI traffic will appear here'))
              : ListView.builder(
                  reverse: true,
                  itemCount: controller.packets.length,
                  itemBuilder: (context, index) {
                    final packet = controller.packets.reversed.elementAt(index);
                    return _PacketTile(packet: packet, controller: controller);
                  },
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
    final time = packet.timestamp;
    final timestamp =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
    return ListTile(
      dense: true,
      leading: Text(packet.direction.name.toUpperCase()),
      title: Text(
        controller.codec.formatHex(packet.bytes),
        style: const TextStyle(fontFamily: 'monospace'),
      ),
      subtitle: Text('$timestamp  ${controller.codec.describe(packet.bytes)}'),
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
