#include <stdint.h>
#include <stdbool.h>
#include "inc/hw_memmap.h"
#include "inc/hw_types.h"
#include "inc/hw_gpio.h"
#include "driverlib/gpio.h"
#include "driverlib/debug.h"
#include "driverlib/sysctl.h"
#include "driverlib/adc.h"
#include "inc/hw_ints.h"

int main(void)
{
	uint32_t pad0_Rx[4] = {0,0,0,0};
	uint32_t pad0_Ry[4] = {0,0,0,0};
	uint32_t pad1_Rx[4] = {0,0,0,0};
	uint32_t pad1_Ry[4] = {0,0,0,0};
	uint32_t pad0_Rx_mean;
	uint32_t pad0_Ry_mean;
	uint32_t pad1_Rx_mean;
	uint32_t pad1_Ry_mean;
	const uint32_t threshold_min = 1900;
	const uint32_t threshold_max = 2100;


	SysCtlClockSet(SYSCTL_SYSDIV_5|SYSCTL_USE_PLL|SYSCTL_OSC_MAIN|SYSCTL_XTAL_16MHZ);

	SysCtlPeripheralEnable(SYSCTL_PERIPH_ADC0);
	SysCtlPeripheralEnable(SYSCTL_PERIPH_ADC1);
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOA);
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOB);
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOC);
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOD);
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOE);
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOF);
	GPIOPinTypeADC(GPIO_PORTD_BASE, GPIO_PIN_2 | GPIO_PIN_3); //D2 = CH5 ; D3 = CH4
	GPIOPinTypeADC(GPIO_PORTE_BASE, GPIO_PIN_2 | GPIO_PIN_3); //E2 = CH1 ; E3 = CH0

	GPIOPinTypeGPIOOutput(GPIO_PORTA_BASE, GPIO_PIN_6 | GPIO_PIN_7 );//pad1Rx
	GPIOPinTypeGPIOOutput(GPIO_PORTC_BASE, GPIO_PIN_4 | GPIO_PIN_5 | GPIO_PIN_6 | GPIO_PIN_7 );//pad0Rx e Ry
	GPIOPinTypeGPIOOutput(GPIO_PORTE_BASE, GPIO_PIN_4 | GPIO_PIN_5 );//pad1Ry
	GPIOPinTypeGPIOOutput(GPIO_PORTF_BASE, GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 );

	HWREG(GPIO_PORTF_BASE + GPIO_O_LOCK) = GPIO_LOCK_KEY;
	HWREG(GPIO_PORTF_BASE + GPIO_O_CR) |= 0x01;
	HWREG(GPIO_PORTF_BASE + GPIO_O_LOCK) = 0;

	ADCSequenceConfigure(ADC0_BASE, 1, ADC_TRIGGER_PROCESSOR, 0);
	ADCSequenceConfigure(ADC0_BASE, 2, ADC_TRIGGER_PROCESSOR, 0);
	ADCSequenceConfigure(ADC1_BASE, 1, ADC_TRIGGER_PROCESSOR, 0);
	ADCSequenceConfigure(ADC1_BASE, 2, ADC_TRIGGER_PROCESSOR, 0);

	ADCSequenceStepConfigure(ADC0_BASE,1,0,ADC_CTL_CH1                       );
	ADCSequenceStepConfigure(ADC0_BASE,1,1,ADC_CTL_CH1                       );
	ADCSequenceStepConfigure(ADC0_BASE,1,2,ADC_CTL_CH1                       );
	ADCSequenceStepConfigure(ADC0_BASE,1,3,ADC_CTL_CH1|ADC_CTL_IE|ADC_CTL_END);

	ADCSequenceStepConfigure(ADC0_BASE,2,0,ADC_CTL_CH0                       );
	ADCSequenceStepConfigure(ADC0_BASE,2,1,ADC_CTL_CH0                       );
	ADCSequenceStepConfigure(ADC0_BASE,2,2,ADC_CTL_CH0                       );
	ADCSequenceStepConfigure(ADC0_BASE,2,3,ADC_CTL_CH0|ADC_CTL_IE|ADC_CTL_END);

	ADCSequenceStepConfigure(ADC1_BASE,1,0,ADC_CTL_CH4                       );
	ADCSequenceStepConfigure(ADC1_BASE,1,1,ADC_CTL_CH4                       );
	ADCSequenceStepConfigure(ADC1_BASE,1,2,ADC_CTL_CH4                       );
	ADCSequenceStepConfigure(ADC1_BASE,1,3,ADC_CTL_CH4|ADC_CTL_IE|ADC_CTL_END);

	ADCSequenceStepConfigure(ADC1_BASE,2,0,ADC_CTL_CH5                       );
	ADCSequenceStepConfigure(ADC1_BASE,2,1,ADC_CTL_CH5                       );
	ADCSequenceStepConfigure(ADC1_BASE,2,2,ADC_CTL_CH5                       );
	ADCSequenceStepConfigure(ADC1_BASE,2,3,ADC_CTL_CH5|ADC_CTL_IE|ADC_CTL_END);

	ADCSequenceEnable(ADC0_BASE, 1);
	ADCSequenceEnable(ADC0_BASE, 2);
	ADCSequenceEnable(ADC1_BASE, 1);
	ADCSequenceEnable(ADC1_BASE, 2);

	while(1)
	{
		ADCIntClear(        ADC0_BASE, 1               );
		ADCProcessorTrigger(ADC0_BASE, 1               );
		while(!ADCIntStatus(ADC0_BASE, 1, false        )){}
		ADCSequenceDataGet( ADC0_BASE, 1, pad0_Ry	   );
		pad0_Ry_mean = (pad0_Ry[0] + pad0_Ry[1] + pad0_Ry[2] + pad0_Ry[3])/4;

		ADCIntClear(        ADC0_BASE, 2               );
		ADCProcessorTrigger(ADC0_BASE, 2               );
		while(!ADCIntStatus(ADC0_BASE, 2, false        )){}
		ADCSequenceDataGet( ADC0_BASE, 2, pad0_Rx	   );
		pad0_Rx_mean = (pad0_Rx[0] + pad0_Rx[1] + pad0_Rx[2] + pad0_Rx[3])/4;

		ADCIntClear(        ADC1_BASE, 1               );
		ADCProcessorTrigger(ADC1_BASE, 1               );
		while(!ADCIntStatus(ADC1_BASE, 1, false        )){}
		ADCSequenceDataGet( ADC1_BASE, 1, pad1_Rx	   );
		pad1_Rx_mean = (pad1_Rx[0] + pad1_Rx[1] + pad1_Rx[2] + pad1_Rx[3])/4;

		ADCIntClear(        ADC1_BASE, 2               );
		ADCProcessorTrigger(ADC1_BASE, 2               );
		while(!ADCIntStatus(ADC1_BASE, 2, false        )){}
		ADCSequenceDataGet( ADC1_BASE, 2, pad1_Ry	   );
		pad1_Ry_mean = (pad1_Ry[0] + pad1_Ry[1] + pad1_Ry[2] + pad1_Ry[3])/4;

		//C4 fica em alto quando há movimento em pad0_Ry
		//C5 = 0 , pad0_Ry movimentou para menos; C5 = 1 , pad0_Ry movimentou para mais;
		if( (pad0_Ry_mean < threshold_min ) || (pad0_Ry_mean > threshold_max) ){
			GPIOPinWrite(GPIO_PORTC_BASE, GPIO_PIN_4, 0xFF );

			if( pad0_Ry_mean < threshold_min  ){
				GPIOPinWrite(GPIO_PORTC_BASE, GPIO_PIN_5, 0x00 );
				GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 , 0x01 );
			}else{
				GPIOPinWrite(GPIO_PORTC_BASE, GPIO_PIN_5, 0xFF );
				GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 , 0x02 );
			};
		}else{ GPIOPinWrite(GPIO_PORTC_BASE, GPIO_PIN_4, 0x00 );
		}

		//C6 fica em alto quando há movimento em pad0_Rx
		//C7 = 0 , pad0_Rx movimentou para menos; C7 = 1 , pad0_Rx movimentou para mais;
		if( (pad0_Rx_mean < threshold_min ) || (pad0_Rx_mean > threshold_max) ){
			GPIOPinWrite(GPIO_PORTC_BASE, GPIO_PIN_6, 0xFF );
			if( pad0_Rx_mean < threshold_min  ){
				GPIOPinWrite(GPIO_PORTC_BASE, GPIO_PIN_7, 0x00 );
				GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 , 0x03 );
			}else{
				GPIOPinWrite(GPIO_PORTC_BASE, GPIO_PIN_7, 0xFF );
				GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 , 0x04 );
			};
		}else{ GPIOPinWrite(GPIO_PORTC_BASE, GPIO_PIN_6, 0x00 );
		}

		//A6 fica em alto quando há movimento em pad1_Rx
		//A7 = 0 , pad1_Rx movimentou para menos; A7 = 1 , pad1_Rx movimentou para mais;
		if( (pad1_Ry_mean < threshold_min ) || (pad1_Ry_mean > threshold_max) ){
			GPIOPinWrite(GPIO_PORTA_BASE, GPIO_PIN_6, 0xFF );

			if( pad1_Ry_mean < threshold_min  ){
				GPIOPinWrite(GPIO_PORTA_BASE, GPIO_PIN_7, 0x00 );
				GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 , 0x05 );
			}else{
				GPIOPinWrite(GPIO_PORTA_BASE, GPIO_PIN_7, 0xFF );
				GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 , 0x06 );
			};
		}else{ GPIOPinWrite(GPIO_PORTA_BASE, GPIO_PIN_6, 0x00 );
		}

		//E4 fica em alto quando há movimento em pad1_Rx
		//E5 = 0 , pad1_Rx movimentou para menos; E5 = 1 , pad1_Rx movimentou para mais;
		if( (pad1_Rx_mean < threshold_min ) || (pad1_Rx_mean > threshold_max) ){
			GPIOPinWrite(GPIO_PORTE_BASE, GPIO_PIN_4, 0xFF );
			if( pad1_Rx_mean < threshold_min  ){
				GPIOPinWrite(GPIO_PORTE_BASE, GPIO_PIN_5, 0x00 );
				GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 , 0x07 );
			}else{
				GPIOPinWrite(GPIO_PORTE_BASE, GPIO_PIN_5, 0xFF );
				GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 , 0x08 );
			};
		}else{ GPIOPinWrite(GPIO_PORTE_BASE, GPIO_PIN_4, 0x00 );
		}


	}
}
