import 'package:flutter/material.dart';

class TrustedCircleScreen extends StatefulWidget {
  const TrustedCircleScreen({Key? key}) : super(key: key);

  @override
  State<TrustedCircleScreen> createState() => _TrustedCircleScreenState();
}

class _TrustedCircleScreenState extends State<TrustedCircleScreen> {
  bool _isDark = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<_Contact> _trustedContacts = [
    _Contact(
      name: 'Mira Patel',
      phone: '+91 9876543210',
      maskedPhone: '+91 98xxxxxx10',
      liveTag: '🏢 CS Block • Floor 2nd •',
      isLive: true,
    ),
    _Contact(
      name: 'Rhea Kapoor',
      phone: '+91 9812345678',
      maskedPhone: '+91 98xxxxxx78',
      liveTag: '📚 Library • Floor Ground •',
      isLive: true,
    ),
    _Contact(
      name: 'Neel Sharma',
      phone: '+91 9900112233',
      maskedPhone: '+91 99xxxxxx33',
      liveTag: null,
      isLive: false,
    ),
    _Contact(
      name: 'Zara Khan',
      phone: '+91 9723456789',
      maskedPhone: '+91 97xxxxxx89',
      liveTag: null,
      isLive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDark ? const Color(0xFF080B16) : const Color(0xFFF4F6FF);
    final cardColor = _isDark ? const Color(0xFF101827) : Colors.white;
    final accentColor = _isDark ? const Color(0xFF7C3AED) : const Color(0xFF5B21B6);
    final inputFill = _isDark ? const Color(0xFF161B2E) : const Color(0xFFF2F4FF);
    final textColor = _isDark ? Colors.white : Colors.black87;

    return Theme(
      data: ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSwatch(
          brightness: _isDark ? Brightness.dark : Brightness.light,
          accentColor: accentColor,
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Trusted Circle',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(_isDark ? Icons.wb_sunny : Icons.nights_stay, color: textColor),
                          onPressed: () => setState(() => _isDark = !_isDark),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _isDark ? const Color(0xFF1F2937) : const Color(0xFFD8D8FF),
                          child: Text('AM', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Name',
                                filled: true,
                                fillColor: _isDark ? const Color(0xFF131827) : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              ),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                hintText: 'Phone',
                                filled: true,
                                fillColor: _isDark ? const Color(0xFF131827) : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              ),
                              style: TextStyle(color: textColor),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5B21B6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                              ),
                              child: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ListView.separated(
                    itemCount: _trustedContacts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final contact = _trustedContacts[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _isDark ? Colors.black.withOpacity(0.35) : Colors.black12,
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: _isDark ? const Color(0xFF2A2E44) : const Color(0xFFEDEBFF),
                                  child: Text(
                                    contact.name.substring(0, 1),
                                    style: TextStyle(color: accentColor, fontWeight: FontWeight.w700, fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(contact.name,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          )),
                                      const SizedBox(height: 4),
                                      Text(contact.maskedPhone,
                                          style: TextStyle(color: _isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                if (contact.isLive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _isDark ? const Color(0xFF12283A) : const Color(0xFFE6FFFA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('LIVE', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 11)),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (contact.liveTag != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(contact.liveTag!, style: TextStyle(color: textColor.withOpacity(0.85), fontSize: 13)),
                              ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _trustedContacts.removeAt(index);
                                  });
                                },
                                icon: Icon(Icons.delete_outline, color: _isDark ? Colors.white54 : Colors.grey[600]),
                                tooltip: 'Remove contact',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Contact {
  final String name;
  final String phone;
  final String maskedPhone;
  final String? liveTag;
  final bool isLive;

  _Contact({
    required this.name,
    required this.phone,
    required this.maskedPhone,
    required this.liveTag,
    required this.isLive,
  });
}
