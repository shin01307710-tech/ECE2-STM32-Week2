/* LAB6 2026-10-26: STM32_2 / UART tasks 5, 6, 7
 * Uses existing v1.1.0 CubeMX project HAL configuration.
 * UART2 (PC) and UART3 (FPGA): 9600 8N1 per teaching plan.
 * NOTE task7 ASCII command mapping is preparatory, not confirmed FPGA protocol.
 */
#include "ece2_474.h"
#include "main.h"
#include <stdint.h>

#define LAB_TASK 7
#define RING_CAPACITY 64U

static uint8_t uart2_rx_byte;
static uint8_t uart3_rx_byte;
static volatile uint8_t pc_buffer[RING_CAPACITY];
static volatile uint8_t fpga_buffer[RING_CAPACITY];
static volatile uint8_t pc_head, pc_tail, fpga_head, fpga_tail;
static volatile uint32_t pc_overflows, fpga_overflows;

/* Called only from the respective UART RX interrupt. */
static void queue_from_isr(volatile uint8_t *ring,
                           volatile uint8_t *head,
                           volatile uint8_t *tail,
                           volatile uint32_t *overflow,
                           uint8_t value)
{
    uint8_t next = (uint8_t)((*head + 1U) & (RING_CAPACITY - 1U));
    if (next == *tail) {
        ++(*overflow);
    } else {
        ring[*head] = value;
        *head = next;
    }
}

/* Called only by the main loop; ISR produces the bytes. */
static uint8_t pop_byte(volatile uint8_t *ring,
                        volatile uint8_t *head,
                        volatile uint8_t *tail,
                        uint8_t *out)
{
    uint8_t current = *tail;
    if (current == *head) return 0U;
    *out = ring[current];
    *tail = (uint8_t)((current + 1U) & (RING_CAPACITY - 1U));
    return 1U;
}

void ece2_474_init(void)
{
    (void)HAL_UART_Receive_IT(&huart2, &uart2_rx_byte, 1U);
#if LAB_TASK == 6 || LAB_TASK == 7
    (void)HAL_UART_Receive_IT(&huart3, &uart3_rx_byte, 1U);
#endif
}

void polling_routine(void)
{
    uint8_t value;
    if (pop_byte(pc_buffer, &pc_head, &pc_tail, &value)) {
#if LAB_TASK == 5
        /* Task 5: PC -> MCU -> PC (single-byte echo). */
        (void)HAL_UART_Transmit(&huart2, &value, 1U, 50U);
#elif LAB_TASK == 6
        /* Task 6: PC -> MCU UART3 -> FPGA. */
        (void)HAL_UART_Transmit(&huart3, &value, 1U, 50U);
#elif LAB_TASK == 7
        /* Task 7 PREPARATION: send ASCII '0'/'1' LED control to FPGA.
         * FPGA must implement the same command decoder before hardware test.
         */
        if (value == (uint8_t)'0' || value == (uint8_t)'1') {
            (void)HAL_UART_Transmit(&huart3, &value, 1U, 50U);
            (void)HAL_UART_Transmit(&huart2, &value, 1U, 50U);
        }
#endif
    }
#if LAB_TASK == 6 || LAB_TASK == 7
    /* FPGA UART3 RX -> MCU -> PC UART2. */
    if (pop_byte(fpga_buffer, &fpga_head, &fpga_tail, &value)) {
        (void)HAL_UART_Transmit(&huart2, &value, 1U, 50U);
    }
#endif
}

/* Required course template ISR entrypoints. */
static void button_isr_p7(void) { }
static void tim6_isr_p4(void) { }
static void gpio_in_pullup_isr_p8_ece2(void) { }
static void gpio_in_pulldown_isr_p9_ece2(void) { }
static void uart2_isr_p6(void)
{
    queue_from_isr(pc_buffer, &pc_head, &pc_tail, &pc_overflows, uart2_rx_byte);
    (void)HAL_UART_Receive_IT(&huart2, &uart2_rx_byte, 1U);
}
static void uart3_isr_p5(void)
{
    queue_from_isr(fpga_buffer, &fpga_head, &fpga_tail,
                   &fpga_overflows, uart3_rx_byte);
    (void)HAL_UART_Receive_IT(&huart3, &uart3_rx_byte, 1U);
}

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
    if (GPIO_Pin == BUTTON_ece2_Pin) button_isr_p7();
    else if (GPIO_Pin == GPIO_IN_PULLUP_ece2_Pin)
        gpio_in_pullup_isr_p8_ece2();
    else if (GPIO_Pin == GPIO_IN_PULLDOWN_ece2_Pin)
        gpio_in_pulldown_isr_p9_ece2();
}
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
    if (htim->Instance == TIM6) tim6_isr_p4();
}
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if (huart->Instance == USART2) uart2_isr_p6();
    else if (huart->Instance == USART3) uart3_isr_p5();
}