let project = new Project('BunnyMark');

project.addAssets('Assets/**');
project.addShaders('shaders/**');
project.addSources('Sources');

resolve(project);
