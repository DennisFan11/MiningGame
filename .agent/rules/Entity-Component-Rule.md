---
trigger: always_on
---

1. Entity 為純資料容器 
2. 靜態資料一律以__data注入
3. 動態資料一律拆出變成component
4. Component 不知道 Entity 和LocalInjector
5. 任何地方都不允許 直接new Entity, 一定只能通過EntityDB生成Entity
6. Entity 禁止被繼承
7. Entity 禁止修改