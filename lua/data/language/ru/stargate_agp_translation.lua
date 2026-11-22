// Ascension Gates: Russian texts CAP never translated

// ===== from stargate.lua =====
stargate_c_tool_21_universe_v2 = Вселенной v2

// ===== from stargate_cap.lua =====
entity_destiny_node = Узел Судьбы
entity_imcd = IMCD
stool_zpm_mk4 = МНТ 4 поколение
vis_shield_design = Новый дизайн пузыря щита

// ===== from stargate_settings.lua =====
// Stargate
sg_sets[stargate][doWormholeSequence] = Последовательность червоточины
sg_sets[stargate][doWormholeSequence][desc] = Проигрывать последовательность перехода с задержкой
sg_sets[stargate][nox_bypass] = Обход руками Ноксов
sg_sets[stargate][nox_bypass][desc] = Разрешить админам с Руками Ноксов полностью проходить сквозь диафрагму

// ZPM MK3
sg_sets[zpm_mk3][explode] = Взрываться
sg_sets[zpm_mk3][explode][desc] = Должен ли МНТ взрываться без хаба?

// ZPM MK4
sg_sets[zpm_mk4] = МНТ 4 поколение (Модуль Нулевой Точки)
sg_sets[zpm_mk4][desc] = Примечание: изменение этих значений может нарушить баланс энергии для набора 8 и 9 шевронов на вратах.
sg_sets[zpm_mk4][capacity] = Емкость
sg_sets[zpm_mk4][capacity][desc] = Как много энергии нулевой точки может содержать МНТ?
sg_sets[zpm_mk4][energy_capacity] = Мощность
sg_sets[zpm_mk4][energy_capacity][desc] = Как много энергии нулевой точки МНТ может конвертировать в "обычную" энергию?
sg_sets[zpm_mk4][explode] = Взрываться
sg_sets[zpm_mk4][explode][desc] = Должен ли МНТ взрываться без хаба?

// Small Powercell
sg_sets[powercell_small] = Малая энергоячейка
sg_sets[powercell_small][capacity] = Емкость
sg_sets[powercell_small][capacity][desc] = Как много энергии может содержать энергоячейка?
sg_sets[powercell_small][energy_capacity] = Мощность
sg_sets[powercell_small][energy_capacity][desc] = Как много энергии может производить энергоячейка?

// Harvester
sg_sets[harvester][harvester_visuals] = Собиратель: визуальный эффект
sg_sets[harvester][harvester_visuals][desc] = Показывать визуальный эффект на экране игрока, когда он находится в собирателе?

// IMCD
sg_sets[imcd] = IMCD (Промышленный молекулярный конструктор)
sg_sets[imcd][allow_tzmp] = Разрешить поддельный МНТ
sg_sets[imcd][allow_tzmp][desc] = Разрешить создание поддельного МНТ (случайно с учётом настройки шанса).
sg_sets[imcd][tzmp_chance] = Шанс на создание
sg_sets[imcd][tzmp_chance][desc] = если шанс = 2, это значит 50%%, 3 будет значить 33%%, и т.д. 1 = всегда.
sg_sets[imcd][speed] = Скорость
sg_sets[imcd][speed][desc] = Скорость создания в процентах
sg_sets[imcd][check_rights] = Проверять права
sg_sets[imcd][check_rights][desc] = Проверять права игроков (группы) для создаваемых устройств.
sg_sets[imcd][require_energy] = Требовать энергию?
sg_sets[imcd][require_energy][desc] = Должен ли IMCD требовать энергию?

// Cap Misc
sg_sets[cap_misc][disable_rings] = Выключить кольца
sg_sets[cap_misc][disable_rings][desc] = Должны ли кольца быть выключены?

// CAP Enhanced
sg_sets[cap_enhanced_cfg] = Ascension Gates Прочее (расширенное)
sg_sets[cap_enhanced_cfg][allow_overload] = Разрешить перегрузку
sg_sets[cap_enhanced_cfg][allow_overload][desc] = Может ли хаб МНТ перегружаться?
sg_sets[cap_enhanced_cfg][hub_advbuttons] = Хаб Атлантиса: расширенный режим кнопок
sg_sets[cap_enhanced_cfg][hub_advbuttons][desc] = Должен ли хаб Атлантиса использовать отдельные кнопки на устройстве?
sg_sets[cap_enhanced_cfg][harvester_visuals] = Цифровые эффекты собирателя
sg_sets[cap_enhanced_cfg][harvester_visuals][desc] = Должен ли собиратель показывать эффект на экране при поглощении?
sg_sets[cap_enhanced_cfg][ATA_gene_active] = Функция гена АТА
sg_sets[cap_enhanced_cfg][ATA_gene_active][desc] = Должны ли некоторые объекты Древних требовать ген АТА?

// ===== from stargate_tools.lua =====
// ZPM MK4
stool_zpm_mk4_spawner = Создатель МНТ 4 поколения
stool_zpm_mk4_create = Создаёт МНТ 4 поколения
stool_zpm_mk4_desc = Левый клик для создания МНТ 4 поколения
stool_zpm_mk4_undone = МНТ 4 поколения удалён
stool_zpm_mk4_cleanup = МНТ 4 поколения
stool_zpm_mk4_cleaned = Удалены все МНТ 4 поколения
stool_zpm_mk4_limit = Достигнут лимит МНТ 4 поколения
stool_zpm_mk4_fulldesc = Это МНТ 4 поколения.
stool_zpm_mk4_capacity = Емкость:
