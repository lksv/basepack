root = FactoryGirl.create(:project, name: "Root")
l1 = FactoryGirl.create(:project, name: "level1", parent: root)
l2 = FactoryGirl.create(:project, name: "level2", parent: root)


l11 = FactoryGirl.create(:project, name: "level11", parent: l1)
l12 = FactoryGirl.create(:project, name: "level12", parent: l1)

l21 = FactoryGirl.create(:project, name: "level21", parent: l2)
l22 = FactoryGirl.create(:project, name: "level22", parent: l2)
l23 = FactoryGirl.create(:project, name: "level23", parent: l2)

l12a = FactoryGirl.create(:project, name: "level12a", parent: l12)
l12b = FactoryGirl.create(:project, name: "level12b", parent: l12)
l12c = FactoryGirl.create(:project, name: "level12c", parent: l12)
