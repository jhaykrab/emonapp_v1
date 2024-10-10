import 'package:flutter/material.dart';
// Import for potential system interactions

// Import DashboardScreen if needed (replace with your actual path)
// import 'package:Emon/screens/dashboard_screen.dart';

class SetupApplianceScreen extends StatefulWidget {
  const SetupApplianceScreen({super.key});

  @override
  State<SetupApplianceScreen> createState() => _SetupApplianceScreenState();
}

class _SetupApplianceScreenState extends State<SetupApplianceScreen> {
  final _formKey = GlobalKey<FormState>();

  // TextEditingController for appliance name
  final _applianceNameController = TextEditingController();

  // List of IconData for appliance icons (using Icons class)
  final List<IconData> _applianceIcons = [
    Icons.lightbulb_outline,
    Icons.air, // Fan icon
    Icons.tv,
    Icons.kitchen, // Refrigerator icon
    // Add more icons from Icons class as needed
  ];
  IconData? _selectedApplianceIcon;

  // List of String values for time units
  final List<String> _timeUnits = ['hrs', 'min', 'sec'];
  String? _selectedTimeUnit;

  // Focus nodes for text fields
  final FocusNode _applianceNameFocusNode = FocusNode();
  final FocusNode _maxUsageLimitFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 72, 100, 68),
          onPressed: () => Navigator.pop(context), // Navigate back
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf5f5f5), Color(0xFFe8f5e9)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    "Let's Set Up Your Appliances!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 72, 100, 68),
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(height: 10),

                  Image.asset(
                    'assets/staticimgs/service-technicians.png',
                    // Replace with appropriate image path
                    height: 250.0,
                    width: 250.0,
                  ),
                  const SizedBox(height: 16),

                  // Appliance Name and Icon Dropdown (Combined)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: TextFormField(
                        controller: _applianceNameController,
                        focusNode: _applianceNameFocusNode,
                        cursorColor: const Color.fromARGB(255, 54, 83, 56),
                        decoration: InputDecoration(
                          labelText: 'Set Appliance Name',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: _applianceNameFocusNode.hasFocus
                                ? const Color.fromARGB(255, 54, 83, 56)
                                : const Color.fromARGB(255, 6, 17, 8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.green.shade800),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 54, 83, 56),
                              width: 2.0,
                            ),
                          ),
                          suffixIcon: DropdownButton<IconData>(
                            value: _selectedApplianceIcon,
                            onChanged: (newValue) {
                              setState(() {
                                _selectedApplianceIcon = newValue;
                              });
                            },
                            items: _applianceIcons.map((icon) {
                              return DropdownMenuItem(
                                value: icon,
                                child: Icon(icon), // Display Icon widget
                              );
                            }).toList(),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an appliance name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // Max Usage Limit and Time Unit Dropdown (Combined)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: IntrinsicHeight(
                        child: TextFormField(
                          focusNode: _maxUsageLimitFocusNode,
                          cursorColor: const Color.fromARGB(255, 54, 83, 56),
                          decoration: InputDecoration(
                            labelText: 'Set Max Usage Limit',
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color: _maxUsageLimitFocusNode.hasFocus
                                  ? const Color.fromARGB(255, 54, 83, 56)
                                  : const Color.fromARGB(255, 6, 17, 8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.green.shade800),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 54, 83, 56),
                                width: 2.0,
                              ),
                            ),
                            suffixIcon: SizedBox(
                              // Wrap DropdownButtonFormField with SizedBox
                              width: 60, // Adjust width as needed
                              child: DropdownButtonFormField<String>(
                                value: _selectedTimeUnit,
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedTimeUnit = newValue!;
                                  });
                                },
                                items: _timeUnits
                                    .map((unit) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(unit),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a max usage limit';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Process the form data
                        // You can access the selected values like this:
                        // _selectedApplianceIcon
                        // _selectedTimeUnit
                        // ... other form field values
                        String applianceName = _applianceNameController.text;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$applianceName has been set successfully!',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 54, 83, 56),
                              ),
                            ),
                            backgroundColor:
                                const Color.fromARGB(255, 193, 223, 194),
                          ),
                        );

                        // Navigate to the dashboard screen after successful save
                        // Ensure that you have defined DashboardScreen and imported it correctly
                        // Navigator.pushReplacement(
                        //   context,
                        //   MaterialPageRoute(builder: (context) => DashboardScreen()),
                        // );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                      padding: const EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 123,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFFe8f5e9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
