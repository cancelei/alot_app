import { Controller } from "@hotwired/stimulus"

/**
 * Lottery Performance Chart Controller
 * 
 * This controller handles the rendering and interaction of lottery performance charts
 * on the admin dashboard and lottery detail pages
 */
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    lotteryId: String,
    chartType: { type: String, default: "volume" }, // volume, bets, players, winRate
    timeRange: { type: String, default: "week" },   // day, week, month, year
    chartData: Object
  }
  
  connect() {
    if (this.hasChartTarget && this.hasChartDataValue) {
      this.initializeChart()
    }
  }
  
  initializeChart() {
    const ctx = this.chartTarget.getContext('2d')
    
    // Extract data from the chartData value
    const { labels, datasets } = this.chartDataValue
    
    // Create the chart
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels,
        datasets
      },
      options: this.getChartOptions()
    })
  }
  
  getChartOptions() {
    // Base options for all chart types
    const baseOptions = {
      responsive: true,
      maintainAspectRatio: false,
      interaction: {
        mode: 'index',
        intersect: false,
      },
      plugins: {
        legend: {
          position: 'top',
        },
        tooltip: {
          callbacks: {
            label: (context) => {
              let label = context.dataset.label || ''
              if (label) {
                label += ': '
              }
              
              // Format based on chart type
              if (this.chartTypeValue === 'volume') {
                label += new Intl.NumberFormat('en-US', { 
                  style: 'currency', 
                  currency: 'USD' 
                }).format(context.parsed.y)
              } else if (this.chartTypeValue === 'winRate') {
                label += context.parsed.y.toFixed(2) + '%'
              } else {
                label += context.parsed.y
              }
              
              return label
            }
          }
        }
      }
    }
    
    // Add specific options based on chart type
    switch (this.chartTypeValue) {
      case 'volume':
        return {
          ...baseOptions,
          scales: {
            y: {
              beginAtZero: true,
              title: {
                display: true,
                text: 'Volume ($)'
              },
              ticks: {
                callback: (value) => {
                  return '$' + value
                }
              }
            },
            x: {
              title: {
                display: true,
                text: 'Date'
              }
            }
          }
        }
        
      case 'winRate':
        return {
          ...baseOptions,
          scales: {
            y: {
              beginAtZero: true,
              max: 100,
              title: {
                display: true,
                text: 'Win Rate (%)'
              },
              ticks: {
                callback: (value) => {
                  return value + '%'
                }
              }
            },
            x: {
              title: {
                display: true,
                text: 'Date'
              }
            }
          }
        }
        
      default:
        return {
          ...baseOptions,
          scales: {
            y: {
              beginAtZero: true,
              title: {
                display: true,
                text: this.chartTypeValue === 'bets' ? 'Number of Bets' : 'Number of Players'
              }
            },
            x: {
              title: {
                display: true,
                text: 'Date'
              }
            }
          }
        }
    }
  }
  
  changeChartType(event) {
    const newChartType = event.currentTarget.dataset.chartType
    if (newChartType && newChartType !== this.chartTypeValue) {
      this.chartTypeValue = newChartType
      
      // Fetch new data for the selected chart type
      this.fetchChartData()
    }
  }
  
  changeTimeRange(event) {
    const newTimeRange = event.currentTarget.dataset.timeRange
    if (newTimeRange && newTimeRange !== this.timeRangeValue) {
      this.timeRangeValue = newTimeRange
      
      // Fetch new data for the selected time range
      this.fetchChartData()
    }
  }
  
  fetchChartData() {
    // Show loading state
    this.chartTarget.classList.add('opacity-50')
    
    // Fetch data from the server
    const url = `/admin/lotteries/${this.lotteryIdValue}/performance_data?chart_type=${this.chartTypeValue}&time_range=${this.timeRangeValue}`
    
    fetch(url, {
      headers: {
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      // Update chart data
      this.chartDataValue = data
      
      // Update the chart
      this.updateChart()
      
      // Remove loading state
      this.chartTarget.classList.remove('opacity-50')
    })
    .catch(error => {
      console.error('Error fetching chart data:', error)
      this.chartTarget.classList.remove('opacity-50')
    })
  }
  
  updateChart() {
    if (!this.chart) return
    
    const { labels, datasets } = this.chartDataValue
    
    // Update chart data
    this.chart.data.labels = labels
    this.chart.data.datasets = datasets
    
    // Update chart options
    this.chart.options = this.getChartOptions()
    
    // Update the chart
    this.chart.update()
  }
}
