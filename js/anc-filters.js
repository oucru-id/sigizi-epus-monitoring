(function () {
  "use strict";

  const readData = (id) => {
    const element = document.getElementById(id);
    return element ? JSON.parse(element.textContent) : [];
  };

  const summaryData = readData("anc-filter-summary-data");
  const kData = readData("anc-filter-k-data");
  const visitData = readData("anc-filter-visits-data");
  const monthSelect = document.getElementById("anc-filter-month");
  const puskesmasSelect = document.getElementById("anc-filter-puskesmas");

  if (!summaryData.length || !monthSelect || !puskesmasSelect) return;

  const escapeHtml = (value) => String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

  const count = (value) => value == null
    ? "Disamarkan"
    : new Intl.NumberFormat("id-ID", { maximumFractionDigits: 0 }).format(value);

  const percentage = (value) => value == null
    ? "Disamarkan"
    : `${new Intl.NumberFormat("id-ID", {
      minimumFractionDigits: 1,
      maximumFractionDigits: 1
    }).format(value)}%`;

  const monthKey = (value) => value == null ? "ALL" : String(value).slice(0, 10);
  const monthLabel = (value) => {
    if (value === "ALL") return "Semua bulan (24 bulan terakhir)";
    return new Intl.DateTimeFormat("id-ID", {
      month: "long",
      year: "numeric",
      timeZone: "UTC"
    }).format(new Date(`${value}T00:00:00Z`));
  };

  const unique = (values) => [...new Set(values)];
  const months = unique(summaryData
    .map((row) => monthKey(row.filter_cohort_month))
    .filter((value) => value !== "ALL"))
    .sort()
    .reverse();
  const puskesmas = unique(summaryData
    .map((row) => row.filter_puskesmas)
    .filter((value) => value && value !== "ALL"))
    .sort((left, right) => left.localeCompare(right, "id"));

  months.forEach((value) => {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = monthLabel(value);
    monthSelect.append(option);
  });

  puskesmas.forEach((value) => {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = value === "UNKNOWN" ? "Tidak diketahui" : value;
    puskesmasSelect.append(option);
  });

  const metricCard = (title, value, note) => `
    <div class="metric-card">
      <h3>${escapeHtml(title)}</h3>
      <div class="metric-value">${escapeHtml(value)}</div>
      <div class="metric-note">${escapeHtml(note)}</div>
    </div>`;

  const chartRow = (label, value, valueLabel, detail, color) => {
    const width = value == null ? 0 : Math.max(0, Math.min(100, Number(value)));
    return `
      <div class="monitor-bar-row">
        <div class="monitor-bar-label">${escapeHtml(label)}</div>
        <div class="monitor-bar-content">
          <div class="monitor-bar-track">
            <div class="monitor-bar-fill" style="width:${width.toFixed(1)}%;background-color:${escapeHtml(color)};"></div>
          </div>
          <div class="monitor-bar-detail">${escapeHtml(detail)}</div>
        </div>
        <div class="monitor-bar-value">${escapeHtml(valueLabel)}</div>
      </div>`;
  };

  const warning = () => `
    <div class="dashboard-filter-warning">
      Hasil untuk kombinasi filter ini disamarkan karena terdapat jumlah
      bukan nol di bawah lima. Pilih “Semua bulan” atau wilayah yang lebih luas.
    </div>`;

  const matches = (row, month, facility) =>
    monthKey(row.filter_cohort_month) === month
      && row.filter_puskesmas === facility;

  function render() {
    const selectedMonth = monthSelect.value;
    const selectedPuskesmas = puskesmasSelect.value;
    const summary = summaryData.find((row) =>
      matches(row, selectedMonth, selectedPuskesmas));
    const context = document.getElementById("anc-filter-context");
    const scorecards = document.getElementById("anc-filter-scorecards");
    const statusChart = document.getElementById("anc-filter-status-chart");
    const visitChart = document.getElementById("anc-filter-visit-chart");
    const kChart = document.getElementById("anc-filter-k-chart");
    const kTable = document.getElementById("anc-filter-k-table");

    const facilityLabel = selectedPuskesmas === "ALL"
      ? "semua puskesmas"
      : selectedPuskesmas === "UNKNOWN"
        ? "puskesmas tidak diketahui"
        : `Puskesmas ${selectedPuskesmas}`;
    context.textContent = `Menampilkan ${monthLabel(selectedMonth).toLowerCase()} dan ${facilityLabel}.`;

    if (!summary || summary.has_suppressed_small_count) {
      [scorecards, statusChart, visitChart, kChart, kTable]
        .filter(Boolean)
        .forEach((element) => { element.innerHTML = warning(); });
      return;
    }

    scorecards.innerHTML = `
      <div class="metric-grid">
        ${metricCard(
          "Ibu hamil aktif",
          count(summary.active_pregnancy_count),
          `Dari ${count(summary.registered_pregnancy_count)} kehamilan terdaftar pada pilihan ini`
        )}
        ${metricCard(
          "Sudah pernah ANC",
          percentage(summary.active_any_anc_percentage),
          `${count(summary.active_with_anc_count)} ibu hamil aktif memiliki ANC bertanggal valid`
        )}
        ${metricCard(
          "Belum pernah ANC",
          count(summary.active_no_anc_count),
          "Prioritas penelusuran karena belum memiliki bukti ANC"
        )}
        ${metricCard(
          "Ada kunjungan terlambat",
          count(summary.active_overdue_count),
          "Sudah pernah ANC, tetapi sedikitnya satu periode K terlewat"
        )}
        ${metricCard(
          "Sesuai jadwal",
          percentage(summary.active_on_schedule_percentage),
          `${count(summary.active_on_schedule_count)} ibu sudah pernah ANC tanpa periode K terlewat`
        )}
        ${metricCard(
          "Lengkap K1–K6",
          percentage(summary.complete_k1_k6_percentage),
          `${count(summary.complete_k1_k6_count)} dari ${count(summary.completed_cohort_denominator_count)} kohort selesai`
        )}
      </div>`;

    const active = Number(summary.active_pregnancy_count) || 0;
    const statuses = [
      ["Belum pernah ANC", summary.active_no_anc_count, "#a63d40"],
      ["Ada kunjungan terlambat", summary.active_overdue_count, "#d46b27"],
      ["Kunjungan sedang jatuh tempo", summary.active_due_now_count, "#d6a51d"],
      ["Lengkap sampai saat ini", summary.active_complete_to_date_count, "#2f855a"]
    ];
    statusChart.innerHTML = `<div class="monitor-bar-chart">${statuses.map((item) => {
      const value = active > 0 && item[1] != null ? 100 * Number(item[1]) / active : null;
      return chartRow(item[0], value, percentage(value), `${count(item[1])} ibu hamil`, item[2]);
    }).join("")}</div>`;

    const visits = visitData.filter((row) =>
      matches(row, selectedMonth, selectedPuskesmas));
    if (!visits.length || visits.some((row) => row.has_suppressed_small_count)) {
      visitChart.innerHTML = warning();
    } else {
      const byCount = new Map(visits.map((row) => [Number(row.completed_k_count), row]));
      visitChart.innerHTML = `<div class="monitor-bar-chart">${[0, 1, 2, 3, 4, 5, 6]
        .map((number) => {
          const row = byCount.get(number);
          const label = number === 0 ? "Belum ada" : `${number} jenis K`;
          return chartRow(
            label,
            row?.pregnancy_percentage ?? 0,
            percentage(row?.pregnancy_percentage ?? 0),
            `${count(row?.pregnancy_count ?? 0)} ibu hamil`,
            "#4f86ad"
          );
        }).join("")}</div>`;
    }

    const stages = kData
      .filter((row) => matches(row, selectedMonth, selectedPuskesmas))
      .sort((left, right) => left.visit_order - right.visit_order);
    if (!stages.length || stages.some((row) => row.has_suppressed_small_count)) {
      kChart.innerHTML = warning();
      kTable.innerHTML = "";
    } else {
      kChart.innerHTML = `<div class="monitor-bar-chart">${stages.map((row) =>
        chartRow(
          `${row.visit_type} (${row.period_label})`,
          row.coverage_percentage,
          percentage(row.coverage_percentage),
          `${count(row.completed_pregnancy_count)} dari ${count(row.eligible_pregnancy_count)} ibu yang sudah mencapai periode`,
          "#2b6f9f"
        )).join("")}</div>`;

      kTable.innerHTML = `
        <div class="table-responsive">
          <table class="caption-top table">
            <thead><tr>
              <th>Kunjungan</th><th>Periode</th><th>Sudah mencapai periode</th>
              <th>Kunjungan tercatat</th><th>Sedang jatuh tempo</th>
              <th>Periode terlewat</th><th>Cakupan</th>
            </tr></thead>
            <tbody>${stages.map((row) => `<tr>
              <td>${escapeHtml(row.visit_type)}</td>
              <td>${escapeHtml(row.period_label)}</td>
              <td>${count(row.eligible_pregnancy_count)}</td>
              <td>${count(row.completed_pregnancy_count)}</td>
              <td>${count(row.currently_due_count)}</td>
              <td>${count(row.missed_window_count)}</td>
              <td>${percentage(row.coverage_percentage)}</td>
            </tr>`).join("")}</tbody>
          </table>
        </div>`;
    }
  }

  monthSelect.addEventListener("change", render);
  puskesmasSelect.addEventListener("change", render);
  document.getElementById("anc-filter-reset")?.addEventListener("click", () => {
    monthSelect.value = "ALL";
    puskesmasSelect.value = "ALL";
    render();
  });

  render();
})();
