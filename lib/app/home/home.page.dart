import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:monekin/app/accounts/account_details.dart';
import 'package:monekin/app/accounts/account_form.dart';
import 'package:monekin/app/home/widgets/drawer.dart';
import 'package:monekin/app/stats/widgets/balance_bar_chart_small.dart';
import 'package:monekin/app/stats/widgets/chart_by_categories.dart';
import 'package:monekin/app/stats/widgets/fund_evolution_line_chart.dart';
import 'package:monekin/app/stats/widgets/income_or_expense_card.dart';
import 'package:monekin/app/transactions/form/transaction_form.page.dart';
import 'package:monekin/app/transactions/transaction_list.dart';
import 'package:monekin/app/transactions/transactions.page.dart';
import 'package:monekin/core/database/app_db.dart';
import 'package:monekin/core/database/services/account/account_service.dart';
import 'package:monekin/core/database/services/transaction/transaction_service.dart';
import 'package:monekin/core/models/account/account.dart';
import 'package:monekin/core/presentation/widgets/animated_progress_bar.dart';
import 'package:monekin/core/presentation/widgets/card_with_header.dart';
import 'package:monekin/core/presentation/widgets/number_ui_formatters/currency_displayer.dart';
import 'package:monekin/core/presentation/widgets/skeleton.dart';
import 'package:monekin/core/presentation/widgets/trending_value.dart';
import 'package:monekin/core/services/filters/date_range_service.dart';
import 'package:monekin/core/services/finance_health_service.dart';
import 'package:monekin/i18n/translations.g.dart';

import '../stats/stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final dateRangeService = DateRangeService();

  late Stream<List<Account>> _accountsStream;

  @override
  void initState() {
    super.initState();

    _accountsStream = AccountService.instance.getAccounts();

    dateRangeService.resetDateRanges();
  }

  Widget buildAccountList(List<Account> accounts) {
    return Builder(
      builder: (context) {
        if (accounts.isEmpty) {
          return Column(
            children: [
              Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        t.home.no_accounts,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.home.no_accounts_descr,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AccountFormPage())),
                          child: Text(t.account.form.create))
                    ],
                  ))
            ],
          );
        }

        return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: accounts.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) {
              return const Divider(indent: 56);
            },
            itemBuilder: (context, index) {
              final account = accounts[index];

              return ListTile(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AccountDetailsPage(account: account))),
                leading: Hero(
                    tag: 'account-icon-${account.id}',
                    child: account.displayIcon(context)),
                trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StreamBuilder(
                          initialData: 0.0,
                          stream: AccountService.instance
                              .getAccountMoney(account: account),
                          builder: (context, snapshot) {
                            return CurrencyDisplayer(
                              amountToConvert: snapshot.data!,
                              currency: account.currency,
                            );
                          }),
                      StreamBuilder(
                          initialData: 0.0,
                          stream: AccountService.instance
                              .getAccountsMoneyVariation(
                                  accounts: [account],
                                  startDate: dateRangeService.startDate,
                                  endDate: dateRangeService.endDate,
                                  convertToPreferredCurrency: false),
                          builder: (context, snapshot) {
                            return TrendingValue(
                              percentage: snapshot.data!,
                              decimalDigits: 0,
                            );
                          }),
                    ]),
                title: Text(account.name),
              );
            });
      },
    );
  }

  _showShouldCreateAccountWarn() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.home.should_create_account_header),
          content: SingleChildScrollView(
              child: Text(t.home.should_create_account_message)),
          actions: [
            TextButton(
              child: Text(t.general.continue_text),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AccountFormPage()));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    final accountService = AccountService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monekin'),
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                dateRangeService
                    .openDateRangeModal(context)
                    .then((_) => setState(() {}));
              },
              icon: const Icon(Icons.calendar_today))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add_rounded),
          onPressed: () {
            TransactionService.instance
                .checkIfCreateTransactionIsPossible()
                .first
                .then((value) {
              if (!value) {
                _showShouldCreateAccountWarn();
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TransactionFormPage()));
              }
            });
          }),
      drawer: const HomeDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Column(
          children: [
            StreamBuilder(
                stream: _accountsStream,
                builder: (context, accounts) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                          '${t.home.total_balance} - ${dateRangeService.selectedDateRange.currentText(context)}',
                          style: const TextStyle(fontSize: 12)),
                      if (!accounts.hasData) ...[
                        const Skeleton(width: 70, height: 40),
                        const Skeleton(width: 30, height: 14),
                      ],
                      if (accounts.hasData) ...[
                        StreamBuilder(
                            stream: accountService.getAccountsMoney(
                                accountIds: accounts.data!.map((e) => e.id)),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return CurrencyDisplayer(
                                  amountToConvert: snapshot.data!,
                                  textStyle: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w600),
                                );
                              }

                              return const Skeleton(width: 90, height: 40);
                            }),
                        if (dateRangeService.startDate != null &&
                            dateRangeService.endDate != null)
                          StreamBuilder(
                              stream: accountService.getAccountsMoneyVariation(
                                  accounts: accounts.data!,
                                  startDate: dateRangeService.startDate,
                                  endDate: dateRangeService.endDate,
                                  convertToPreferredCurrency: true),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Skeleton(width: 52, height: 22);
                                }

                                return TrendingValue(
                                  percentage: snapshot.data!,
                                  filled: true,
                                  fontWeight: FontWeight.bold,
                                  outlined: true,
                                );
                              }),
                      ]
                    ],
                  );
                }),
            const SizedBox(height: 24),
            Row(
              children: [
                IncomeOrExpenseCard(
                  type: AccountDataFilter.income,
                  startDate: dateRangeService.startDate,
                  endDate: dateRangeService.endDate,
                ),
                IncomeOrExpenseCard(
                  type: AccountDataFilter.expense,
                  startDate: dateRangeService.startDate,
                  endDate: dateRangeService.endDate,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder(
                stream: AccountService.instance.getAccounts(
                  predicate: (acc, curr) => acc.isArchived.isNotValue(true),
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CardWithHeader(
                        title: t.home.active_accounts,
                        body: const LinearProgressIndicator());
                  } else {
                    final accounts = snapshot.data!;

                    return CardWithHeader(
                        title: t.home.active_accounts,
                        headerButtonIcon: Icons.add_rounded,
                        onHeaderButtonClick: accounts.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AccountFormPage()));
                              },
                        body: buildAccountList(accounts));
                  }
                }),
            const SizedBox(
              height: 16,
            ),
            StreamBuilder(
                stream: TransactionService.instance
                    .checkIfCreateTransactionIsPossible(),
                builder: (context, accountSnapshot) {
                  return CardWithHeader(
                    title: t.home.last_transactions,
                    onHeaderButtonClick:
                        accountSnapshot.hasData && accountSnapshot.data!
                            ? () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const TransactionsPage()));
                              }
                            : null,
                    body: StreamBuilder(
                        stream: TransactionService.instance.getTransactions(
                            predicate: (transaction,
                                    account,
                                    accountCurrency,
                                    receivingAccount,
                                    receivingAccountCurrency,
                                    c,
                                    p6) =>
                                AppDB.instance.buildExpr([
                                  if (dateRangeService.startDate != null)
                                    transaction.date.isBiggerOrEqualValue(
                                        dateRangeService.startDate!),
                                  if (dateRangeService.endDate != null)
                                    transaction.date.isSmallerThanValue(
                                        dateRangeService.endDate!)
                                ]),
                            limit: 5,
                            orderBy: (p0, p1, p2, p3, p4, p5, p6) =>
                                drift.OrderBy([
                                  drift.OrderingTerm(
                                      expression: p0.date,
                                      mode: drift.OrderingMode.desc)
                                ])),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const LinearProgressIndicator();
                          }

                          if (snapshot.data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                t.transaction.list.empty,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return TransactionListComponent(
                              transactions: snapshot.data!,
                              showGroupDivider: false,
                              prevPage: const HomePage());
                        }),
                  );
                }),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              return Wrap(
                runSpacing: 16,
                spacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: constraints.maxWidth > 600
                        ? constraints.maxWidth / 2 - 16
                        : double.infinity,
                    child: CardWithHeader(
                      title: t.financial_health.display,
                      body: StreamBuilder(
                          stream: _accountsStream,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const LinearProgressIndicator();
                            }

                            final accounts = snapshot.data!;

                            return Padding(
                                padding: const EdgeInsets.all(16),
                                child: StreamBuilder(
                                    initialData: 0.0,
                                    stream:
                                        FinanceHealthService().getHealthyValue(
                                      accounts: accounts,
                                      startDate: dateRangeService.startDate,
                                      endDate: dateRangeService.endDate,
                                    ),
                                    builder: (context, snapshot) {
                                      Color getHealthyValueColor(
                                              double healthyValue) =>
                                          HSLColor.fromAHSL(
                                                  1, healthyValue, 1, 0.35)
                                              .toColor();

                                      return ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxHeight: 180),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            AnimatedProgressBar(
                                              value: snapshot.data! / 100,
                                              direction: Axis.vertical,
                                              width: 16,
                                              color: getHealthyValueColor(
                                                  snapshot.data!),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .baseline,
                                                          textBaseline:
                                                              TextBaseline
                                                                  .alphabetic,
                                                          children: [
                                                            Text(
                                                              snapshot.data!
                                                                  .toStringAsFixed(
                                                                      0),
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headlineMedium!
                                                                  .copyWith(
                                                                    color: getHealthyValueColor(
                                                                        snapshot
                                                                            .data!),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                            ),
                                                            const Text(' / 100')
                                                          ]),
                                                      Text(
                                                        FinanceHealthService()
                                                            .getHealthyValueReviewTitle(
                                                                context,
                                                                snapshot.data!),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium!
                                                            .copyWith(
                                                              color:
                                                                  getHealthyValueColor(
                                                                      snapshot
                                                                          .data!),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    FinanceHealthService()
                                                        .getHealthyValueReviewDescr(
                                                            context,
                                                            snapshot.data!),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      );
                                    }));
                          }),
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth > 600
                        ? constraints.maxWidth / 2 - 16
                        : double.infinity,
                    child: CardWithHeader(
                        title: t.stats.balance_evolution,
                        body: FundEvolutionLineChart(
                          startDate: dateRangeService.startDate,
                          endDate: dateRangeService.endDate,
                          dateRange: dateRangeService.selectedDateRange,
                        ),
                        onHeaderButtonClick: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const StatsPage(
                                        initialIndex: 1,
                                      )));
                        }),
                  )
                ],
              );
            }),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              return Wrap(
                runSpacing: 16,
                spacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: constraints.maxWidth > 600
                        ? constraints.maxWidth / 2 - 16
                        : double.infinity,
                    child: CardWithHeader(
                        title: t.stats.by_categories,
                        body: ChartByCategories(
                          startDate: dateRangeService.startDate,
                          endDate: dateRangeService.endDate,
                        ),
                        onHeaderButtonClick: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const StatsPage(
                                        initialIndex: 0,
                                      )));
                        }),
                  ),
                  SizedBox(
                    width: constraints.maxWidth > 600
                        ? constraints.maxWidth / 2 - 16
                        : double.infinity,
                    child: CardWithHeader(
                        title: t.stats.cash_flow,
                        body: Padding(
                          padding: const EdgeInsets.only(
                              top: 16, left: 16, right: 16),
                          child: BalanceChartSmall(
                              dateRangeService: dateRangeService),
                        ),
                        onHeaderButtonClick: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const StatsPage(
                                        initialIndex: 2,
                                      )));
                        }),
                  )
                ],
              );
            }),
            const SizedBox(height: 64)
          ],
        ),
      ),
    );
  }
}