import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  runApp(const MuhannadAccountingApp());
}

class MuhannadAccountingApp extends StatelessWidget {
  const MuhannadAccountingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مهند للأنظمة المحاسبية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Cairo', useMaterial3: true),
      home: const Directionality(textDirection: TextDirection.rtl, child: MainHomeScreen()),
    );
  }
}

// ------------------- نماذج البيانات -------------------
class Customer {
  int? id; String name, phone; String? email; double balance; String createdDate; String? lastActivity, notes; String level;
  Customer({this.id, required this.name, required this.phone, this.email, required this.balance, required this.createdDate, this.lastActivity, this.notes, this.level = 'عادي'});
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'phone': phone, 'email': email, 'balance': balance, 'createdDate': createdDate, 'lastActivity': lastActivity, 'notes': notes, 'level': level};
  factory Customer.fromMap(Map<String, dynamic> map) => Customer(id: map['id'], name: map['name'], phone: map['phone'], email: map['email'], balance: map['balance'], createdDate: map['createdDate'], lastActivity: map['lastActivity'], notes: map['notes'], level: map['level'] ?? 'عادي');
}

class Product {
  int? id; String name, sku; double price; int stock; String category; String? supplier, expiryDate;
  Product({this.id, required this.name, required this.sku, required this.price, required this.stock, required this.category, this.supplier, this.expiryDate});
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'sku': sku, 'price': price, 'stock': stock, 'category': category, 'supplier': supplier, 'expiryDate': expiryDate};
  factory Product.fromMap(Map<String, dynamic> map) => Product(id: map['id'], name: map['name'], sku: map['sku'], price: map['price'], stock: map['stock'], category: map['category'], supplier: map['supplier'], expiryDate: map['expiryDate']);
}

class Transaction {
  int? id; String date, description, type, currency, fund, account; double amount;
  Transaction({this.id, required this.date, required this.description, required this.type, required this.amount, required this.currency, required this.fund, required this.account});
  Map<String, dynamic> toMap() => {'id': id, 'date': date, 'description': description, 'type': type, 'amount': amount, 'currency': currency, 'fund': fund, 'account': account};
  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(id: map['id'], date: map['date'], description: map['description'], type: map['type'], amount: map['amount'], currency: map['currency'], fund: map['fund'], account: map['account']);
}

class CashMovement {
  int? id; String date, type, description, fund, user; double amount;
  CashMovement({this.id, required this.date, required this.type, required this.amount, required this.description, required this.fund, required this.user});
  Map<String, dynamic> toMap() => {'id': id, 'date': date, 'type': type, 'amount': amount, 'description': description, 'fund': fund, 'user': user};
  factory CashMovement.fromMap(Map<String, dynamic> map) => CashMovement(id: map['id'], date: map['date'], type: map['type'], amount: map['amount'], description: map['description'], fund: map['fund'], user: map['user']);
}

class Invoice {
  int? id; String invoiceNumber; int customerId; String date; String? dueDate; double subtotal, discount, tax, total, paidAmount; String status; String? notes;
  Invoice({this.id, required this.invoiceNumber, required this.customerId, required this.date, this.dueDate, required this.subtotal, required this.discount, required this.tax, required this.total, required this.paidAmount, required this.status, this.notes});
  Map<String, dynamic> toMap() => {'id': id, 'invoiceNumber': invoiceNumber, 'customerId': customerId, 'date': date, 'dueDate': dueDate, 'subtotal': subtotal, 'discount': discount, 'tax': tax, 'total': total, 'paidAmount': paidAmount, 'status': status, 'notes': notes};
  factory Invoice.fromMap(Map<String, dynamic> map) => Invoice(id: map['id'], invoiceNumber: map['invoiceNumber'], customerId: map['customerId'], date: map['date'], dueDate: map['dueDate'], subtotal: map['subtotal'], discount: map['discount'], tax: map['tax'], total: map['total'], paidAmount: map['paidAmount'], status: map['status'], notes: map['notes']);
}

class InvoiceItem {
  int? id; int invoiceId; int productId; int quantity; double unitPrice, discount, total;
  InvoiceItem({this.id, required this.invoiceId, required this.productId, required this.quantity, required this.unitPrice, required this.discount, required this.total});
  Map<String, dynamic> toMap() => {'id': id, 'invoiceId': invoiceId, 'productId': productId, 'quantity': quantity, 'unitPrice': unitPrice, 'discount': discount, 'total': total};
  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(id: map['id'], invoiceId: map['invoiceId'], productId: map['productId'], quantity: map['quantity'], unitPrice: map['unitPrice'], discount: map['discount'], total: map['total']);
}

// ------------------- قاعدة البيانات -------------------
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal(); factory DatabaseHelper() => _instance; DatabaseHelper._internal();
  static Database? _database;
  Future<Database> get database async { if (_database != null) return _database!; _database = await _initDatabase(); return _database!; }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = '${documentsDirectory.path}/muhannad_accounting.db';
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL, email TEXT, balance REAL NOT NULL, createdDate TEXT NOT NULL, lastActivity TEXT, notes TEXT, level TEXT)');
    await db.execute('CREATE TABLE products (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, sku TEXT NOT NULL, price REAL NOT NULL, stock INTEGER NOT NULL, category TEXT NOT NULL, supplier TEXT, expiryDate TEXT)');
    await db.execute('CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, description TEXT NOT NULL, type TEXT NOT NULL, amount REAL NOT NULL, currency TEXT NOT NULL, fund TEXT NOT NULL, account TEXT NOT NULL)');
    await db.execute('CREATE TABLE cash_movements (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, type TEXT NOT NULL, amount REAL NOT NULL, description TEXT NOT NULL, fund TEXT NOT NULL, user TEXT NOT NULL)');
    await db.execute('CREATE TABLE invoices (id INTEGER PRIMARY KEY AUTOINCREMENT, invoiceNumber TEXT UNIQUE NOT NULL, customerId INTEGER NOT NULL, date TEXT NOT NULL, dueDate TEXT, subtotal REAL NOT NULL, discount REAL NOT NULL, tax REAL NOT NULL, total REAL NOT NULL, paidAmount REAL NOT NULL, status TEXT NOT NULL, notes TEXT, FOREIGN KEY(customerId) REFERENCES customers(id))');
    await db.execute('CREATE TABLE invoice_items (id INTEGER PRIMARY KEY AUTOINCREMENT, invoiceId INTEGER NOT NULL, productId INTEGER NOT NULL, quantity INTEGER NOT NULL, unitPrice REAL NOT NULL, discount REAL NOT NULL, total REAL NOT NULL, FOREIGN KEY(invoiceId) REFERENCES invoices(id), FOREIGN KEY(productId) REFERENCES products(id))');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE invoices (id INTEGER PRIMARY KEY AUTOINCREMENT, invoiceNumber TEXT UNIQUE NOT NULL, customerId INTEGER NOT NULL, date TEXT NOT NULL, dueDate TEXT, subtotal REAL NOT NULL, discount REAL NOT NULL, tax REAL NOT NULL, total REAL NOT NULL, paidAmount REAL NOT NULL, status TEXT NOT NULL, notes TEXT, FOREIGN KEY(customerId) REFERENCES customers(id))');
      await db.execute('CREATE TABLE invoice_items (id INTEGER PRIMARY KEY AUTOINCREMENT, invoiceId INTEGER NOT NULL, productId INTEGER NOT NULL, quantity INTEGER NOT NULL, unitPrice REAL NOT NULL, discount REAL NOT NULL, total REAL NOT NULL, FOREIGN KEY(invoiceId) REFERENCES invoices(id), FOREIGN KEY(productId) REFERENCES products(id))');
    }
  }

  // العملاء
  Future<int> insertCustomer(Customer c) async { Database db = await database; return await db.insert('customers', c.toMap()); }
  Future<List<Customer>> getCustomers() async { Database db = await database; final List<Map<String, dynamic>> maps = await db.query('customers'); return List.generate(maps.length, (i) => Customer.fromMap(maps[i])); }
  Future<Customer?> getCustomer(int id) async { Database db = await database; List<Map<String,dynamic>> maps = await db.query('customers', where: 'id = ?', whereArgs: [id]); if (maps.isEmpty) return null; return Customer.fromMap(maps.first); }
  Future<int> updateCustomer(Customer c) async { Database db = await database; return await db.update('customers', c.toMap(), where: 'id = ?', whereArgs: [c.id]); }

  // المنتجات
  Future<int> insertProduct(Product p) async { Database db = await database; return await db.insert('products', p.toMap()); }
  Future<List<Product>> getProducts() async { Database db = await database; final List<Map<String, dynamic>> maps = await db.query('products'); return List.generate(maps.length, (i) => Product.fromMap(maps[i])); }
  Future<Product?> getProduct(int id) async { Database db = await database; List<Map<String,dynamic>> maps = await db.query('products', where: 'id = ?', whereArgs: [id]); if (maps.isEmpty) return null; return Product.fromMap(maps.first); }
  Future<int> updateProduct(Product p) async { Database db = await database; return await db.update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]); }

  // المعاملات
  Future<int> insertTransaction(Transaction t) async { Database db = await database; return await db.insert('transactions', t.toMap()); }
  Future<List<Transaction>> getTransactions() async { Database db = await database; final List<Map<String, dynamic>> maps = await db.query('transactions'); return List.generate(maps.length, (i) => Transaction.fromMap(maps[i])); }

  // الصندوق
  Future<int> insertCashMovement(CashMovement c) async { Database db = await database; return await db.insert('cash_movements', c.toMap()); }
  Future<List<CashMovement>> getCashMovements() async { Database db = await database; final List<Map<String, dynamic>> maps = await db.query('cash_movements'); return List.generate(maps.length, (i) => CashMovement.fromMap(maps[i])); }

  // الفواتير
  Future<int> insertInvoice(Invoice invoice) async { Database db = await database; return await db.insert('invoices', invoice.toMap()); }
  Future<int> insertInvoiceItem(InvoiceItem item) async { Database db = await database; return await db.insert('invoice_items', item.toMap()); }
  Future<List<Invoice>> getInvoices() async { Database db = await database; final List<Map<String, dynamic>> maps = await db.query('invoices', orderBy: 'id DESC'); return List.generate(maps.length, (i) => Invoice.fromMap(maps[i])); }
  Future<Invoice?> getInvoice(int id) async { Database db = await database; List<Map<String,dynamic>> maps = await db.query('invoices', where: 'id = ?', whereArgs: [id]); if (maps.isEmpty) return null; return Invoice.fromMap(maps.first); }
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async { Database db = await database; final List<Map<String, dynamic>> maps = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]); return List.generate(maps.length, (i) => InvoiceItem.fromMap(maps[i])); }
  Future<int> updateInvoice(Invoice invoice) async { Database db = await database; return await db.update('invoices', invoice.toMap(), where: 'id = ?', whereArgs: [invoice.id]); }
  Future<void> deleteInvoice(int invoiceId) async { Database db = await database; await db.delete('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]); await db.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]); }
  Future<String> getNextInvoiceNumber() async { Database db = await database; var result = await db.rawQuery('SELECT MAX(id) as maxId FROM invoices'); int nextId = 1; if (result.isNotEmpty && result.first['maxId'] != null) { nextId = (result.first['maxId'] as int) + 1; } return 'INV-${nextId.toString().padLeft(6, '0')}'; }

  // منطق إنشاء الفاتورة (مع الآثار الجانبية)
  Future<void> createInvoiceWithEffects({required int customerId, required List<Map<String, dynamic>> items, required double discount, required double tax, required bool isCash, String? dueDate, String? notes}) async {
    Database db = await database;
    double subtotal = 0;
    List<Map<String, dynamic>> itemData = [];
    for (var item in items) {
      double lineTotal = (item['unitPrice'] * item['quantity']) - item['discount'];
      subtotal += lineTotal;
      itemData.add({'productId': item['productId'], 'quantity': item['quantity'], 'unitPrice': item['unitPrice'], 'discount': item['discount'], 'total': lineTotal});
    }
    double total = subtotal - discount + tax;
    String invoiceNumber = await getNextInvoiceNumber();
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Invoice invoice = Invoice(
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      date: currentDate,
      dueDate: dueDate,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      total: total,
      paidAmount: isCash ? total : 0,
      status: isCash ? 'مدفوعة' : 'آجل',
      notes: notes,
    );
    int invoiceId = await insertInvoice(invoice);

    for (var item in itemData) {
      await insertInvoiceItem(InvoiceItem(invoiceId: invoiceId, productId: item['productId'], quantity: item['quantity'], unitPrice: item['unitPrice'], discount: item['discount'], total: item['total']));
      Product? product = await getProduct(item['productId']);
      if (product != null) { product.stock -= item['quantity']; await updateProduct(product); }
    }

    Customer? customer = await getCustomer(customerId);
    if (customer != null && !isCash) { customer.balance += total; await updateCustomer(customer); }

    if (isCash) {
      await insertTransaction(Transaction(date: currentDate, description: 'فاتورة نقدية #$invoiceNumber', type: 'income', amount: total, currency: 'usd', fund: 'main', account: 'cash'));
      await insertCashMovement(CashMovement(date: currentDate, type: 'دخول', amount: total, description: 'فاتورة نقدية #$invoiceNumber', fund: 'رئيسي', user: 'مدير'));
    } else {
      await insertTransaction(Transaction(date: currentDate, description: 'فاتورة آجلة #$invoiceNumber للعميل ${customer?.name}', type: 'income', amount: total, currency: 'usd', fund: 'main', account: 'accounts_receivable'));
    }
  }

  Future<void> recordPayment(int invoiceId, double amount) async {
    Invoice? invoice = await getInvoice(invoiceId);
    if (invoice == null) return;
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    double newPaid = invoice.paidAmount + amount;
    String newStatus = 'جزئي';
    if (newPaid >= invoice.total) { newStatus = 'مدفوعة'; newPaid = invoice.total; }
    Invoice updatedInvoice = invoice; updatedInvoice.paidAmount = newPaid; updatedInvoice.status = newStatus; await updateInvoice(updatedInvoice);
    Customer? customer = await getCustomer(invoice.customerId);
    if (customer != null) { customer.balance -= amount; if (customer.balance < 0) customer.balance = 0; await updateCustomer(customer); }
    await insertTransaction(Transaction(date: currentDate, description: 'دفعة على فاتورة #${invoice.invoiceNumber}', type: 'income', amount: amount, currency: 'usd', fund: 'main', account: 'cash'));
    await insertCashMovement(CashMovement(date: currentDate, type: 'دخول', amount: amount, description: 'دفعة على فاتورة #${invoice.invoiceNumber}', fund: 'رئيسي', user: 'مدير'));
  }

  Future<void> cancelInvoice(int invoiceId) async {
    Invoice? invoice = await getInvoice(invoiceId);
    if (invoice == null || invoice.status == 'ملغاة') return;
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<InvoiceItem> items = await getInvoiceItems(invoiceId);
    for (var item in items) { Product? product = await getProduct(item.productId); if (product != null) { product.stock += item.quantity; await updateProduct(product); } }
    Customer? customer = await getCustomer(invoice.customerId);
    if (customer != null && invoice.status != 'مدفوعة') { customer.balance -= invoice.total; if (customer.balance < 0) customer.balance = 0; await updateCustomer(customer); }
    Invoice updatedInvoice = invoice; updatedInvoice.status = 'ملغاة'; await updateInvoice(updatedInvoice);
    await insertTransaction(Transaction(date: currentDate, description: 'إلغاء فاتورة #${invoice.invoiceNumber}', type: 'expense', amount: invoice.total, currency: 'usd', fund: 'main', account: 'sales_return'));
  }
}

// ------------------- الشاشة الرئيسية -------------------
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);
  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}
class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const DashboardScreen(), const CustomersScreen(), const ProductsScreen(),
    const InvoicesScreen(), const LedgerScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مهند للأنظمة المحاسبية'), actions: [IconButton(icon: const Icon(Icons.sync), onPressed: () => setState(() {}))]),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'العملاء'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المخزون'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'الفواتير'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'القيود'),
        ],
      ),
    );
  }
}

// ------------------- لوحة التحكم -------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  int _customers = 0, _products = 0, _invoices = 0; double _totalIncome = 0, _totalExpense = 0; bool _loading = true;
  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async { final db = DatabaseHelper(); final customers = await db.getCustomers(); final products = await db.getProducts(); final invoices = await db.getInvoices(); final transactions = await db.getTransactions(); double income = 0, expense = 0; for (var t in transactions) { if (t.type == 'income') income += t.amount; else expense += t.amount; } setState(() { _customers = customers.length; _products = products.length; _invoices = invoices.length; _totalIncome = income; _totalExpense = expense; _loading = false; }); }
  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📊 نظرة عامة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12,
          children: [
            _buildCard('الرصيد', '${(_totalIncome - _totalExpense).toStringAsFixed(1)} \$', Icons.account_balance, Colors.blue),
            _buildCard('الإيرادات', '${_totalIncome.toStringAsFixed(1)} \$', Icons.trending_up, Colors.green),
            _buildCard('المصروفات', '${_totalExpense.toStringAsFixed(1)} \$', Icons.trending_down, Colors.red),
            _buildCard('الفواتير', '$_invoices', Icons.receipt_long, Colors.orange),
            _buildCard('العملاء', '$_customers', Icons.people, Colors.purple),
            _buildCard('المنتجات', '$_products', Icons.inventory, Colors.teal),
          ],
        ),
        const SizedBox(height: 20),
        const Text('⚡ إجراءات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildAction('فاتورة جديدة', Icons.add, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()))),
          _buildAction('عميل', Icons.person_add, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen()))),
          _buildAction('منتج', Icons.add_box, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()))),
        ]),
      ]),
    );
  }
  Widget _buildCard(String title, String value, IconData icon, Color color) => Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 30), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey))])));
  Widget _buildAction(String label, IconData icon, VoidCallback onTap) => ElevatedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label), style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))));
}

// ------------------- العملاء -------------------
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}
class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = []; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final db = DatabaseHelper(); final c = await db.getCustomers(); setState(() { _customers = c; _loading = false; }); }
  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('العملاء'), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen())).then((_) => _load()), icon: const Icon(Icons.add))]),
      body: ListView.builder(itemCount: _customers.length, itemBuilder: (ctx, i) { final c = _customers[i]; return ListTile(leading: CircleAvatar(child: Text(c.name[0])), title: Text(c.name), subtitle: Text(c.phone), trailing: Text(c.balance > 0 ? 'عليه ${c.balance}' : 'له ${-c.balance}', style: TextStyle(color: c.balance > 0 ? Colors.red : Colors.green)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerProfileScreen(customer: c)))); }),
    );
  }
}
class CustomerProfileScreen extends StatelessWidget {
  final Customer customer;
  const CustomerProfileScreen({Key? key, required this.customer}) : super(key: key);
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 40, child: Text(customer.name[0], style: const TextStyle(fontSize: 30))),
          const SizedBox(height: 12),
          Text('📞 ${customer.phone}'), if (customer.email != null) Text('📧 ${customer.email}'),
          Text('الرصيد: ${customer.balance > 0 ? "عليه ${customer.balance}" : "له ${-customer.balance}"}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: customer.balance > 0 ? Colors.red : Colors.green)),
          Text('تاريخ الفتح: ${customer.createdDate}'), if (customer.notes != null) Text('ملاحظات: ${customer.notes}'),
          const SizedBox(height: 20),
          Row(children: [
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.receipt), label: const Text('كشف حساب')),
            const SizedBox(width: 10),
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit), label: const Text('تعديل')),
          ]),
        ]),
      ),
    );
  }
}
class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({Key? key}) : super(key: key);
  @override State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}
class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>(); final _name = TextEditingController(), _phone = TextEditingController(), _email = TextEditingController(), _balance = TextEditingController();
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة عميل')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم'), validator: (v) => v!.isEmpty ? 'أدخل الاسم' : null),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'رقم الهاتف'), validator: (v) => v!.isEmpty ? 'أدخل رقم الهاتف' : null),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني (اختياري)')),
            TextFormField(controller: _balance, decoration: const InputDecoration(labelText: 'الرصيد الافتتاحي (موجب = عليه)'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () async { if (_formKey.currentState!.validate()) { final db = DatabaseHelper(); await db.insertCustomer(Customer(name: _name.text, phone: _phone.text, email: _email.text.isNotEmpty ? _email.text : null, balance: double.tryParse(_balance.text) ?? 0, createdDate: DateFormat('yyyy-MM-dd').format(DateTime.now()))); Navigator.pop(context); } }, child: const Text('حفظ')),
          ]),
        ),
      ),
    );
  }
}

// ------------------- المنتجات -------------------
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);
  @override State<ProductsScreen> createState() => _ProductsScreenState();
}
class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = []; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final db = DatabaseHelper(); final p = await db.getProducts(); setState(() { _products = p; _loading = false; }); }
  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('المنتجات'), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())).then((_) => _load()), icon: const Icon(Icons.add))]),
      body: ListView.builder(itemCount: _products.length, itemBuilder: (ctx, i) { final p = _products[i]; return ListTile(title: Text(p.name), subtitle: Text('SKU: ${p.sku} | المخزون: ${p.stock}'), trailing: Text('${p.price}\$', style: const TextStyle(fontWeight: FontWeight.bold))); }),
    );
  }
}
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);
  @override State<AddProductScreen> createState() => _AddProductScreenState();
}
class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>(); final _name = TextEditingController(), _sku = TextEditingController(), _price = TextEditingController(), _stock = TextEditingController(), _category = TextEditingController();
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم'), validator: (v) => v!.isEmpty ? 'أدخل الاسم' : null),
            TextFormField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU'), validator: (v) => v!.isEmpty ? 'أدخل SKU' : null),
            TextFormField(controller: _price, decoration: const InputDecoration(labelText: 'السعر'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'أدخل السعر' : null),
            TextFormField(controller: _stock, decoration: const InputDecoration(labelText: 'الكمية'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'أدخل الكمية' : null),
            TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'التصنيف'), validator: (v) => v!.isEmpty ? 'أدخل التصنيف' : null),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () async { if (_formKey.currentState!.validate()) { final db = DatabaseHelper(); await db.insertProduct(Product(name: _name.text, sku: _sku.text, price: double.parse(_price.text), stock: int.parse(_stock.text), category: _category.text)); Navigator.pop(context); } }, child: const Text('حفظ')),
          ]),
        ),
      ),
    );
  }
}

// ------------------- الفواتير -------------------
class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);
  @override State<InvoicesScreen> createState() => _InvoicesScreenState();
}
class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Invoice> _invoices = []; bool _loading = true; String _filter = 'الكل';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final db = DatabaseHelper(); final inv = await db.getInvoices(); setState(() { _invoices = inv; _loading = false; }); }
  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    List<Invoice> filtered = _invoices.where((i) => _filter == 'الكل' || i.status == _filter).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
        actions: [
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen())).then((_) => _load()), icon: const Icon(Icons.add)),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (ctx) => ['الكل', 'مدفوعة', 'آجل', 'جزئي', 'ملغاة', 'مرتجع'].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (ctx, i) {
          final inv = filtered[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              title: Text('#${inv.invoiceNumber}'),
              subtitle: Text('${inv.date} | المجموع: ${inv.total}\$'),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(inv.status, style: TextStyle(color: inv.status == 'مدفوعة' ? Colors.green : inv.status == 'آجل' ? Colors.orange : Colors.red)),
                  Text('متبقي: ${(inv.total - inv.paidAmount).toStringAsFixed(1)}\$', style: const TextStyle(fontSize: 12)),
                ],
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoiceId: inv.id!))).then((_) => _load()),
            ),
          );
        },
      ),
    );
  }
}

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({Key? key}) : super(key: key);
  @override State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}
class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final db = DatabaseHelper();
  List<Customer> _customers = [];
  List<Product> _products = [];
  int? _selectedCustomerId;
  List<Map<String, dynamic>> _items = [];
  double _discount = 0, _tax = 0;
  bool _isCash = false;
  String? _dueDate;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async { final c = await db.getCustomers(); final p = await db.getProducts(); setState(() { _customers = c; _products = p; }); }

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) {
        int? productId; int qty = 1; double price = 0, disc = 0;
        return AlertDialog(
          title: const Text('إضافة منتج'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'المنتج'),
                items: _products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) { productId = v; final p = _products.firstWhere((x) => x.id == v); price = p.price; },
              ),
              TextFormField(decoration: const InputDecoration(labelText: 'الكمية'), initialValue: '1', keyboardType: TextInputType.number, onChanged: (v) => qty = int.tryParse(v) ?? 1),
              TextFormField(decoration: const InputDecoration(labelText: 'سعر الوحدة'), initialValue: price.toString(), keyboardType: TextInputType.number, onChanged: (v) => price = double.tryParse(v) ?? 0),
              TextFormField(decoration: const InputDecoration(labelText: 'خصم'), initialValue: '0', keyboardType: TextInputType.number, onChanged: (v) => disc = double.tryParse(v) ?? 0),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            TextButton(onPressed: () { if (productId != null && qty > 0) { setState(() => _items.add({'productId': productId!, 'quantity': qty, 'unitPrice': price, 'discount': disc})); } Navigator.pop(ctx); }, child: const Text('إضافة')),
          ],
        );
      },
    );
  }
  void _removeItem(int index) => setState(() => _items.removeAt(index));
  double get _subtotal => _items.fold(0, (sum, i) => sum + ((i['unitPrice'] * i['quantity']) - i['discount']));
  double get _total => _subtotal - _discount + _tax;

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء فاتورة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'العميل'),
              items: _customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _selectedCustomerId = v),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text('إجمالي البنود: ${_items.length}', style: const TextStyle(fontWeight: FontWeight.bold))),
              ElevatedButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('إضافة منتج')),
            ]),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  final product = _products.firstWhere((p) => p.id == item['productId'], orElse: () => Product(id: 0, name: 'غير معروف', sku: '', price: 0, stock: 0, category: ''));
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('كمية: ${item['quantity']} | السعر: ${item['unitPrice']} | خصم: ${item['discount']}'),
                    trailing: IconButton(onPressed: () => _removeItem(i), icon: const Icon(Icons.delete, color: Colors.red)),
                  );
                },
              ),
            ),
            TextField(decoration: const InputDecoration(labelText: 'خصم إضافي'), keyboardType: TextInputType.number, onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0)),
            TextField(decoration: const InputDecoration(labelText: 'ضريبة'), keyboardType: TextInputType.number, onChanged: (v) => setState(() => _tax = double.tryParse(v) ?? 0)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('الإجمالي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${_total.toStringAsFixed(2)}\$', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            ]),
            Row(children: [
              Checkbox(value: _isCash, onChanged: (v) => setState(() => _isCash = v!)),
              const Text('فاتورة نقدية'),
            ]),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (_selectedCustomerId == null || _items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر عميل وأضف منتجات')));
                  return;
                }
                await db.createInvoiceWithEffects(customerId: _selectedCustomerId!, items: _items, discount: _discount, tax: _tax, isCash: _isCash, dueDate: _dueDate);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('حفظ الفاتورة'),
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceDetailsScreen extends StatefulWidget {
  final int invoiceId;
  const InvoiceDetailsScreen({Key? key, required this.invoiceId}) : super(key: key);
  @override State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}
class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  Invoice? _invoice; List<InvoiceItem> _items = []; bool _loading = true; final db = DatabaseHelper();
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final inv = await db.getInvoice(widget.invoiceId); final items = await db.getInvoiceItems(widget.invoiceId); setState(() { _invoice = inv; _items = items; _loading = false; }); }
  @override Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_invoice == null) return const Scaffold(body: Center(child: Text('غير موجودة')));
    final inv = _invoice!;
    return Scaffold(
      appBar: AppBar(title: Text('فاتورة #${inv.invoiceNumber}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('التاريخ: ${inv.date}', style: const TextStyle(fontSize: 16)),
          Text('الحالة: ${inv.status}', style: TextStyle(fontSize: 16, color: inv.status == 'مدفوعة' ? Colors.green : Colors.orange)),
          Text('الإجمالي: ${inv.total}\$', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('المدفوع: ${inv.paidAmount}\$', style: const TextStyle(fontSize: 16)),
          const Divider(),
          const Text('البنود:', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final item = _items[i];
                return ListTile(title: Text('المنتج ID: ${item.productId}'), subtitle: Text('كمية: ${item.quantity} | السعر: ${item.unitPrice} | الإجمالي: ${item.total}'));
              },
            ),
          ),
          if (inv.status == 'آجل' || inv.status == 'جزئي')
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () async { await db.recordPayment(widget.invoiceId, inv.total - inv.paidAmount); _load(); }, icon: const Icon(Icons.payment), label: const Text('دفع الكل'))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(onPressed: () async {
                final amt = await showDialog<double>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('دفعة جزئية'),
                  content: TextField(decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number, onChanged: (v) {}),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('إلغاء')),
                    TextButton(onPressed: () { double val = double.tryParse((ctx.findChildOfType<TextField>()?.controller?.text) ?? '0') ?? 0; Navigator.pop(ctx, val); }, child: const Text('دفع')),
                  ],
                ));
                if (amt != null && amt > 0) { await db.recordPayment(widget.invoiceId, amt); _load(); }
              }, icon: const Icon(Icons.partial), label: const Text('دفع جزئي'))),
            ]),
          if (inv.status != 'ملغاة' && inv.status != 'مرتجع')
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () async { await db.cancelInvoice(widget.invoiceId); _load(); }, icon: const Icon(Icons.cancel, color: Colors.white), label: const Text('إلغاء الفاتورة'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red))),
            ]),
        ]),
      ),
    );
  }
}

// ------------------- القيود -------------------
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({Key? key}) : super(key: key);
  @override State<LedgerScreen> createState() => _LedgerScreenState();
}
class _LedgerScreenState extends State<LedgerScreen> {
  List<Transaction> _transactions = []; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final db = DatabaseHelper(); final t = await db.getTransactions(); setState(() { _transactions = t; _loading = false; }); }
  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    double totalDebit = _transactions.where((t) => t.type == 'income').fold(0, (s, t) => s + t.amount);
    double totalCredit = _transactions.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Expanded(child: Card(color: Colors.green.shade50, child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [const Text('إجمالي له', style: TextStyle(fontSize: 12, color: Colors.grey)), Text('$totalDebit', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))])))),
          const SizedBox(width: 10),
          Expanded(child: Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [const Text('إجمالي عليه', style: TextStyle(fontSize: 12, color: Colors.grey)), Text('$totalCredit', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red))])))),
        ]),
        const SizedBox(height: 16),
        ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _transactions.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (ctx, i) { final t = _transactions[i]; return ListTile(title: Text(t.description), subtitle: Text('${t.date} | ${t.account}'), trailing: Text('${t.type == 'income' ? '+' : '-'} ${t.amount}', style: TextStyle(color: t.type == 'income' ? Colors.green : Colors.red))); }),
      ]),
    );
  }
}
