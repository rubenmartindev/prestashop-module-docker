<?php
/**
 * @author rubenmartin.dev <hola@rubenmartin.dev>
 *
 * @copyright Since 2026 rubenmartin.dev
 *
 * @license https://opensource.org/license/MIT MIT
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

class MyModule extends Module
{
    public function __construct()
    {
        $this->author                   = 'rubenmartin.dev';
        $this->bootstrap                = true;
        $this->name                     = 'mymodule';
        $this->need_instance            = 0;
        $this->ps_versions_compliancy   = ['min' => '1.6', 'max' => '9.999'];
        $this->tab                      = 'others';
        $this->version                  = '0.0.0';

        parent::__construct();

        $this->displayName = $this->l('MyModule');
        $this->description = $this->l('Example module');
    }
}
