<?php

$config = new class () extends PrestaShop\CodingStandards\CsFixer\Config {
    public function getRules(): array
    {
        return array_merge(
            parent::getRules(),
            [
                '@PSR12' => true,
                'blank_line_after_opening_tag' => false,
                'no_blank_lines_after_phpdoc' => false,
                'phpdoc_separation' => [
                    'groups' => [
                        ['ORM\\*'],
                    ],
                ],
                'phpdoc_indent' => true,
                'phpdoc_line_span' => [
                    'case' => 'multi',
                    'class' => 'multi',
                    'const' => 'multi',
                    'function' => 'multi',
                    'method' => 'multi',
                    'other' => null,
                    'property' => 'multi',
                    'trait_import' => 'multi',
                ],
                'phpdoc_tag_casing' => true,
                'phpdoc_trim' => true,
                'phpdoc_trim_consecutive_blank_line_separation' => true,
                'ordered_imports' => true,
            ],
        );
    }
};

$config
    ->setUsingCache(true)
    ->getFinder()
    ->in(__DIR__)
    ->exclude('vendor');

return $config;
