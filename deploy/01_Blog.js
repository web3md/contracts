module.exports = async ({getNamedAccounts, deployments}) => {
  const {deployer} = await getNamedAccounts();
  const {create2} = deployments;
  const {deploy} = await create2("Blog", {
    from: deployer,
    log: true,
  });
  await deploy();
};
