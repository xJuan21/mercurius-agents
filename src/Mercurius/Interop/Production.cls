Class Mercurius.Interop.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Mercurius.Interop.Production" LogGeneralTraceEvents="false">
  <Item Name="DocumentIngress" ClassName="Mercurius.Interop.BS.DocumentIngress" PoolSize="1" Enabled="true">
    <Setting Target="Host" Name="AgentName">Scribe</Setting>
    <Setting Target="Host" Name="EventType">Document</Setting>
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/inbox/documents/</Setting>
    <Setting Target="Adapter" Name="FileSpec">*</Setting>
  </Item>
  <Item Name="AlertIngress" ClassName="Mercurius.Interop.BS.DocumentIngress" PoolSize="1" Enabled="true">
    <Setting Target="Host" Name="AgentName">Sentinel</Setting>
    <Setting Target="Host" Name="EventType">Alert</Setting>
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/inbox/alerts/</Setting>
    <Setting Target="Adapter" Name="FileSpec">*</Setting>
  </Item>
  <Item Name="AgentWorkflow" ClassName="Mercurius.Interop.BP.AgentWorkflow" PoolSize="1" Enabled="true"/>
  <Item Name="AgentRunner" ClassName="Mercurius.Interop.BO.AgentRunner" PoolSize="1" Enabled="true"/>
  <Item Name="ResultHandler" ClassName="Mercurius.Interop.BO.ResultHandler" PoolSize="1" Enabled="true"/>
  <Item Name="ReviewQueue" ClassName="Mercurius.Interop.BO.ResultHandler" PoolSize="1" Enabled="true"/>
</Production>
}

}
