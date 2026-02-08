import 'package:flutter/material.dart';

class Step3MessagePreviewWidget extends StatelessWidget {
  const Step3MessagePreviewWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MESSAGE PREVIEW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            // Phone Mockup
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF111827)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: Container(
                height: 160,
                width: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCa6FHxHCdHOoP5TJhIu2cA0sG2XBlvNsIG6kIjt17wusBF4cg0ipjFlLic8CfwKG-_RLx3MT3V_02TWboHg_uq48iLuiDJmVFtMiEjBeTJYkUUTTKuZPGcprOnqMEtO8mJwECniE3BXx6g7qc474TItTmESSOmBCGh0g54YzNycOHc1WQWuWtpE8zLYOJoXftjFOiF-IDczKpR2iPRYSH_y0Fwvvoj5PKy-VTdgJrNa0M5qWxg9pjefAs7lVG6ptwOHxeUK9auOHw',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                // child: SingleChildScrollView(
                //   padding: const EdgeInsets.all(16),
                //   child: Column(
                //     mainAxisAlignment: MainAxisAlignment.end,
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Container(
                //         constraints: const BoxConstraints(maxWidth: 240),
                //         padding: const EdgeInsets.all(12),
                //         decoration: BoxDecoration(
                //           color: isDark ? const Color(0xFF1F2C34) : Colors.white,
                //           borderRadius: BorderRadius.circular(8),
                //           boxShadow: [
                //             BoxShadow(
                //               color: Colors.black.withValues(alpha:0.1),
                //               blurRadius: 8,
                //               offset: const Offset(0, 2),
                //             ),
                //           ],
                //         ),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             Row(
                //               children: [
                //                 const Text(
                //                   'Holiday Sale! ',
                //                   style: TextStyle(
                //                     fontSize: 12,
                //                     fontWeight: FontWeight.bold,
                //                     color: Color(0xFF3B82F6),
                //                   ),
                //                 ),
                //                 Text(
                //                   '🎄',
                //                   style: TextStyle(
                //                     fontSize: 12,
                //                     color: isDark
                //                         ? const Color(0xFFE5E7EB)
                //                         : const Color(0xFF111827),
                //                   ),
                //                 ),
                //               ],
                //             ),
                //             const SizedBox(height: 4),
                //             RichText(
                //               text: TextSpan(
                //                 style: TextStyle(
                //                   fontSize: 11,
                //                   height: 1.4,
                //                   color: isDark
                //                       ? const Color(0xFFE5E7EB)
                //                       : const Color(0xFF111827),
                //                 ),
                //                 children: [
                //                   const TextSpan(text: 'Hello '),
                //                   WidgetSpan(
                //                     child: Container(
                //                       padding: const EdgeInsets.symmetric(
                //                         horizontal: 4,
                //                         vertical: 1,
                //                       ),
                //                       decoration: BoxDecoration(
                //                         color: const Color(
                //                           0xFF137FEC,
                //                         ).withValues(alpha:0.1),
                //                         borderRadius: BorderRadius.circular(3),
                //                       ),
                //                       child: const Text(
                //                         '{{customer_name}}',
                //                         style: TextStyle(
                //                           fontSize: 10,
                //                           color: Color(0xFF137FEC),
                //                           fontFamily: 'monospace',
                //                         ),
                //                       ),
                //                     ),
                //                   ),
                //                   const TextSpan(text: ','),
                //                 ],
                //               ),
                //             ),
                //             const SizedBox(height: 8),
                //             RichText(
                //               text: TextSpan(
                //                 style: TextStyle(
                //                   fontSize: 11,
                //                   height: 1.4,
                //                   color: isDark
                //                       ? const Color(0xFFE5E7EB)
                //                       : const Color(0xFF111827),
                //                 ),
                //                 children: [
                //                   const TextSpan(
                //                     text:
                //                         "Don't miss our exclusive holiday deals. Get up to 40% off on all items. Use code ",
                //                   ),
                //                   WidgetSpan(
                //                     child: Container(
                //                       padding: const EdgeInsets.symmetric(
                //                         horizontal: 4,
                //                         vertical: 1,
                //                       ),
                //                       decoration: BoxDecoration(
                //                         color: const Color(
                //                           0xFF137FEC,
                //                         ).withValues(alpha:0.1),
                //                         borderRadius: BorderRadius.circular(3),
                //                       ),
                //                       child: const Text(
                //                         'HOLIDAY40',
                //                         style: TextStyle(
                //                           fontSize: 10,
                //                           color: Color(0xFF137FEC),
                //                           fontFamily: 'monospace',
                //                         ),
                //                       ),
                //                     ),
                //                   ),
                //                   const TextSpan(text: ' at checkout!'),
                //                 ],
                //               ),
                //             ),
                //             const SizedBox(height: 8),
                //             Align(
                //               alignment: Alignment.centerRight,
                //               child: Text(
                //                 '4:30 PM',
                //                 style: TextStyle(
                //                   fontSize: 10,
                //                   color: isDark
                //                       ? const Color(0xFF6B7280)
                //                       : const Color(0xFF9CA3AF),
                //                 ),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2C34) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Holiday Sale! ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    Text(
                      '🎄',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF111827),
                    ),
                    children: [
                      const TextSpan(text: 'Hello '),
                      WidgetSpan(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF137FEC,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            '{{customer_name}}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF137FEC),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ','),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF111827),
                    ),
                    children: [
                      const TextSpan(
                        text:
                            "Don't miss our exclusive holiday deals. Get up to 40% off on all items. Use code ",
                      ),
                      WidgetSpan(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF137FEC,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'HOLIDAY40',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF137FEC),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' at checkout!'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '4:30 PM',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
