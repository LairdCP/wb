/*
 * For the wb40nbt to use w/Dongle-Host-Driver module.
 *   D.Siganos for Lairdtech
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/gpio.h>

static int wifireset_init(void)
{
    printk(KERN_INFO "Asserting Wifi Reset\n");
    at91_set_gpio_output(AT91_PIN_PB13, 0);
    return 0;
}

static void wifireset_exit(void)
{
    at91_set_gpio_output(AT91_PIN_PB13, 1);
    printk(KERN_INFO "Deasserting Wifi Reset\n");
}

module_init(wifireset_init);
module_exit(wifireset_exit);

