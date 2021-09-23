# myExpense 💵

Personal web app expense application.

## What is this sh\*t? 🤔

This code is part of myExpense application, an Expense and Income tracker.

The intent behind this application is to create an expense application that can support multi currency, so we can utilise a single application to track our expense.

The code here is the front-end part of the myExpense which compiled and serve as web app.

<strong>What WEB APP? 😡</strong>

Yes web app, I knew a lot of people will say that Web App on Flutter is not <i>"production"</i> ready, but as this application is going to be used by my self only, so the liability of the bug free application is not really that demanding.

Thus, I can ensure you that this application most likely is sh\*t one. I am not an expert in Flutter, and I can say that this is my first project that I create using Flutter, after trying them once or two on the early Flutter (and forget about it afterwards).

<i>I was trying a lot of other framework (Ionic, Vue, React either with Onsen or Antd ) before decide to Flutter just because Flutter have Cupertino Date Time Picker (Antd also have, but I am not really good at reading chinese, so, Flutter it is), and I think my decision is correct one as I can focus on creating a simple UI without needed a hefty knowledge of design.</i>

<strong>Note:</strong> The backend part of this application currently is not being open-source yet, but as the function of the application is simple enough, I think creating a backend application is not as hard nor as demanding also.

## What is the Application looks like? 😎
Below is the screenshot of the application in action.

### Login Page 🔑
<img src="https://user-images.githubusercontent.com/20193342/134541954-d503a7ba-9ee7-44d6-84b5-5ddc5ad57769.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134541954-d503a7ba-9ee7-44d6-84b5-5ddc5ad57769.png" width="350" />

### Pin Page ⌨
This page will be showed if user setup PIN for their configuration. PIN is stored in a secured box using Hive.
|Pin Page|Pin Input|
|--------|---------|
|<img src="https://user-images.githubusercontent.com/20193342/134542618-faba0777-cccf-4a85-8556-4515659dd8dd.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134542618-faba0777-cccf-4a85-8556-4515659dd8dd.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134542634-cd441a63-68a8-487a-b24d-fd92755f9c19.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134542634-cd441a63-68a8-487a-b24d-fd92755f9c19.png" width="350" />|

### Home Page 🏠
#### Transaction List 📃
In transaction list page, you can navigate all your expense using Calendar.

|Transaction List|Table Calendar|
|----------------|--------------|
|<img src="https://user-images.githubusercontent.com/20193342/134543327-a9cbc174-80db-4a18-90d6-b8f42ed89deb.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134543327-a9cbc174-80db-4a18-90d6-b8f42ed89deb.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134543347-7ea1309e-7a0a-49f3-9ab4-108a6303b9a1.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134543347-7ea1309e-7a0a-49f3-9ab4-108a6303b9a1.png" width="350" />|

If you click the Month and Year title on the AppBar it will showed the calendar for you to jump to distant date, instead navigating and scrolling one by one.

|Click Appbar|Navigate On Calendar|Click OK|
|------------|--------------------|--------|
|<img src="https://user-images.githubusercontent.com/20193342/134543395-a7bdd054-a1c5-45ec-8095-cd2fd01dba2c.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134543395-a7bdd054-a1c5-45ec-8095-cd2fd01dba2c.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134543419-63daa330-a7d4-438b-b73e-58f04fd955fd.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134543419-63daa330-a7d4-438b-b73e-58f04fd955fd.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134543473-953e0378-c897-4f7d-a567-b87e81543cbb.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134543473-953e0378-c897-4f7d-a567-b87e81543cbb.png" width="350" />|

All the transaction being fetched from server will be cache on the local storage.

### Statistics 📈
#### Summary Stats 📊
This page will showed you the summary of the all the account you have, how much income and expense (in total and in average) that you have on the current month.

|Summary Stats|Stats Bar Chart|
|-------------|---------------|
|<img src="https://user-images.githubusercontent.com/20193342/134545116-6d9639f7-5654-4012-b691-e24fae4ff354.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134545116-6d9639f7-5654-4012-b691-e24fae4ff354.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134545146-9f75fa5c-fafa-404d-9b86-fc2364cf4dd9.JPG" data-canonical-src="https://user-images.githubusercontent.com/20193342/134545146-9f75fa5c-fafa-404d-9b86-fc2364cf4dd9.JPG" width="350" />|

You can navigate to the other month, either by click the month arrow on the header or by swiping left and right on the screen.

#### Detail Stats 🧿

You can also perform query of all your expense and income, based on currency, date, and account that you want to see the statistics.

To do this, you can click on the Pie Chart icon on the top right, and it will showed you the Filter Stats Page.

|Filter By Month|Filter By Year|Filter By Custom|
|---------------|--------------|----------------|
|<img src="https://user-images.githubusercontent.com/20193342/134545640-b75090a8-e1fb-4bc1-a345-67cdc7577ecb.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134545640-b75090a8-e1fb-4bc1-a345-67cdc7577ecb.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134545655-a8375022-7fc4-49cb-a6bd-8dd1fdcfa69a.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134545655-a8375022-7fc4-49cb-a6bd-8dd1fdcfa69a.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134545659-70964e92-c99e-4329-9ff0-187fb8292ba2.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134545659-70964e92-c99e-4329-9ff0-187fb8292ba2.png" width="350" />|

When you press the "Filter Statistics" button or the "Start" icon on the top right, it will send request to backend, and backend will perform calculation based on the filter statisctics given by user input. Once finished, it will be showed on the Detail Statistic Page.

|Stats Income|Stats Expense|
|------------|-------------|
|<img src="https://user-images.githubusercontent.com/20193342/134546142-235380b4-c361-4ad7-9b26-b8f9567ca816.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134546142-235380b4-c361-4ad7-9b26-b8f9567ca816.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134546158-ff5c167d-e2f0-4f27-a659-ebd860afe574.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134546158-ff5c167d-e2f0-4f27-a659-ebd860afe574.png" width="350" />|

If you clicked on the income/expense category it will showed you the detail transaction that you performed during the date that you input.

<img src="https://user-images.githubusercontent.com/20193342/134546402-5b9ff65e-5079-43e6-8787-c52ef913654a.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134546402-5b9ff65e-5079-43e6-8787-c52ef913654a.png" width="350" />

### Budget 💯
In budget page, you can control the budget for specific category, and you can configure a different budget category for each currency that you have on your wallet.

The first page that will be showed on the budget page is the "default currency" budget that you can configure on the User page.

<img src="https://user-images.githubusercontent.com/20193342/134548463-55ba7eaf-2a90-4205-9fbb-e35ff6504718.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134548463-55ba7eaf-2a90-4205-9fbb-e35ff6504718.png" width="350" />

Here you can see how much is your expense related to the total budget, and each category to see which category is already passed the budget.

To select different currency, you can tap on the Currency Selection on the Budget Bar header, and it will showed you the list of currency that we have on our Wallet/Account.

<img src="https://user-images.githubusercontent.com/20193342/134548726-40f16117-3881-4211-acd2-3f89cedb109f.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134548726-40f16117-3881-4211-acd2-3f89cedb109f.png" width="350" />

When you click the expense category, you will directed to detail transaction for that expense category. In there you can see what is the detail of the expense you performed on that category.

<img src="https://user-images.githubusercontent.com/20193342/134548925-20043f3b-bb2f-4825-afbb-3c57376b98d3.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134548925-20043f3b-bb2f-4825-afbb-3c57376b98d3.png" width="350" />

To configure the expense category on the budget, you can click on the "Settings" icon on the top left. It will direct you to the Budget List page.

#### Budget List 📃

The page will listed all your budget list on the currency currently selected on the budget page. To add new category, you can press the Add Category button, to Edit the current expense category you can double tap the expense category, and once finished you can press the Save button on the top left.

|Budget List|Add New Budget|Edit Budget|
|-----------|--------------|-----------|
|<img src="https://user-images.githubusercontent.com/20193342/134549361-26d8df7f-e9ee-437f-9367-5c4930c76601.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134549361-26d8df7f-e9ee-437f-9367-5c4930c76601.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134549385-ceaf910a-8127-411e-ac06-8642b0c5c8f9.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134549385-ceaf910a-8127-411e-ac06-8642b0c5c8f9.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134549406-450d60dd-f00e-40a2-a8df-e001ab603790.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134549406-450d60dd-f00e-40a2-a8df-e001ab603790.png" width="350" />|

### Account 🎫
In here you can see all your wallet/account, it will showed you the current balance of your wallet/account also.

#### Account List 📃
<img src="https://user-images.githubusercontent.com/20193342/134549709-69590a85-9aab-429e-8be9-3f085625de80.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134549709-69590a85-9aab-429e-8be9-3f085625de80.png" width="350" />

There are several action on the account that you can do, such as Edit, Disable, and Delete. You can do this by slide the account and it will give you the options.

<img src="https://user-images.githubusercontent.com/20193342/134550219-66ff39e5-0771-41ad-9904-4076adfa0ccf.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134550219-66ff39e5-0771-41ad-9904-4076adfa0ccf.png" width="350" />

The account that disabled will not going to be showed when you adding the transaction, or in the statistics pages. Account that disabled will be marked with dark grey color.

#### Account Detail ℹ
You can see the detail transaction of each account, by tap the account, and it will showed you the transaction that performed on that account on the current month.

<img src="https://user-images.githubusercontent.com/20193342/134549978-5c23ef27-0f2d-4650-b20a-c1b0d261b3da.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134549978-5c23ef27-0f2d-4650-b20a-c1b0d261b3da.png" width="350" />

#### Add Account ➕
On the add account page, you can give the account name, account type, starting balance, and what is the currency of the account. You can also decide whether you want to include the account on the statistics computation or not, or whether the account already disabled or not?

|Add Account|Account Type|Currency Type|
|-----------|------------|-------------|
|<img src="https://user-images.githubusercontent.com/20193342/134550896-7776b556-f532-42ab-92e1-af84fac8f4a8.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134550896-7776b556-f532-42ab-92e1-af84fac8f4a8.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134550893-488cfa0c-b75f-4403-9672-621161f5d0be.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134550893-488cfa0c-b75f-4403-9672-621161f5d0be.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134550883-8484501a-f306-4df1-9e3e-1c1a42aca84d.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134550883-8484501a-f306-4df1-9e3e-1c1a42aca84d.png" width="350" />|

### Transaction 💸

When you adding/edit the transaction, you can choose either this 3 type of transaction:
* Expense
* Income
* Transfer

|Expense|Income|Transfer|
|-------|------|--------|
|<img src="https://user-images.githubusercontent.com/20193342/134551253-dd37e72b-8096-4b14-80aa-c8e34c66a20e.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134551253-dd37e72b-8096-4b14-80aa-c8e34c66a20e.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134551261-0181e305-8f35-45bb-8b60-1e00c5f92d2c.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134551261-0181e305-8f35-45bb-8b60-1e00c5f92d2c.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134551258-6ca9c5a5-bbd7-4ea6-99c4-e1f1e0e8e7ec.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134551258-6ca9c5a5-bbd7-4ea6-99c4-e1f1e0e8e7ec.png" width="350" />|

#### Input Transaction 🔠
When you input the transaction, it will showed you custom Pin Pad that that also act as calculator, and you can choose the category, and date of the transaction. You can also define this transaction is performed on which account, and whether there are any description on the transaction or not. This Cupertino Date Time Picker is the first reason why I am choosing Flutter when I create this application. 

|Custom Calc|Date Time Picker|Account Selection|Description|
|-----------|----------------|-----------------|-----------|
|<img src="https://user-images.githubusercontent.com/20193342/134551434-c161ef0d-e7c3-45b8-85f7-5846a0ff61a5.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134551434-c161ef0d-e7c3-45b8-85f7-5846a0ff61a5.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134551814-169820ce-c084-40bd-a0c3-72f96646a22f.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134551814-169820ce-c084-40bd-a0c3-72f96646a22f.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134551823-431f5043-0d1e-45f3-852e-22b3922156db.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134551823-431f5043-0d1e-45f3-852e-22b3922156db.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134551851-d7c92d20-24a4-420e-81c3-82efcbf7fca5.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134551851-d7c92d20-24a4-420e-81c3-82efcbf7fca5.png" width="350" />|

There are also "auto complete" feature during the transaction input, that will be generate based on the expense or income that you already performed. This will be only showed if only the virtual keyboard is being open on the screen.

<img src="https://user-images.githubusercontent.com/20193342/134552854-442f2a57-b7b5-4ad7-97bb-34167eebfb28.JPG" data-canonical-src="https://user-images.githubusercontent.com/20193342/134552854-442f2a57-b7b5-4ad7-97bb-34167eebfb28.JPG" width="350" />

When you perform Transfer, in case it have different currency, it will showed you the exchane rate box.

|Transfer Same Currency|Transfer Different Currency|
|----------------------|---------------------------|
|<img src="https://user-images.githubusercontent.com/20193342/134552138-a79359e9-8eeb-45e4-a798-be0e8ab3f3a0.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134552138-a79359e9-8eeb-45e4-a798-be0e8ab3f3a0.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134552146-2577da42-3752-4e31-b560-b52facac96ae.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134552146-2577da42-3752-4e31-b560-b52facac96ae.png" width="350" />|

### Search 🔎

You can perform search on the transaction, and the result for the tranasction will be showed lazy loading, so we will not fetch too many data.

|Search Fields|Search Result|
|-------------|-------------|
|<img src="https://user-images.githubusercontent.com/20193342/134553007-89c2f8a9-be68-42f6-a1ad-60548fb68732.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134553007-89c2f8a9-be68-42f6-a1ad-60548fb68732.png" width="350" />|<img src="https://user-images.githubusercontent.com/20193342/134553012-9c0db6ec-6d44-4b26-925e-c29e59291096.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134553012-9c0db6ec-6d44-4b26-925e-c29e59291096.png" width="350" />|


### User Page 👤

The user configuration page, here you can configure all the default value.
* Default Expense: Expense category that will be automatically populated during add expense transaction
* Default Income: Income category that will be automatically populated during add income transaction
* Default Budget Currency: Used on the budget page to showed which currency will be showed first
* Default Wallet: Wallet/account that will be automatically populated during add expense/income/transfer transaction. In the transaction transaction the default wallet will be put on the "Transfer To"

Here you can also control whether you want to change your password, or enable/disable the PIN.

<img src="https://user-images.githubusercontent.com/20193342/134553495-363860fe-cd02-48cc-ae1c-7e64eda82fba.png" data-canonical-src="https://user-images.githubusercontent.com/20193342/134553495-363860fe-cd02-48cc-ae1c-7e64eda82fba.png" width="350" />

## Run...Run...Run...

Before you press your F5, change the .dev.env files, so it will point to the correct backend-server.

## Build It! 

Use `./docker_build.sh` to build the application for production.

It will clean your flutter project, perform pub get, and build it using main.prod.dart instead of main.dart.

The main.prod.dart will load the Production ENV Configuration file.
